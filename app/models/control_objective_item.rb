class ControlObjectiveItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :review => {
      :column => "LOWER(#{Review.table_name}.identification)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :process_control => {
      :column => "LOWER(#{ProcessControl.table_name}.name)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :control_objective_text => {
      :column => "LOWER(#{table_name}.control_objective_text)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    }
  })

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:pre_audit_workpaper_ids,
    :post_audit_workpaper_ids]

  # Atributos no persistentes
  attr_reader :approval_errors

  # Callbacks
  before_validation :can_be_modified?, :enable_control_validations
  before_destroy :can_be_destroyed?
  before_validation_on_create :fill_control_objective_text

  # Validaciones
  validates_presence_of :control_objective_text, :control_objective_id
  validates_numericality_of :control_objective_id, :review_id,
    :allow_nil => true, :only_integer => true
  validates_numericality_of :relevance, :only_integer => true,
    :allow_blank => true, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_date :audit_date, :allow_nil => true, :allow_blank => true
  validates_each :audit_date do |record, attr, value|
    period = record.review.period if record.review

    if period && value && !value.between?(period.start, period.end)
      record.errors.add attr, :out_of_period
    end
  end
  validates_each :control_objective_id do |record, attr, value|
    review = record.review
    
    is_duplicated = review && review.control_objective_items.any? do |coi|
      another_record = (!record.new_record? && coi.id != record.id) ||
        (record.new_record? && coi.object_id != record.object_id)

      coi.control_objective_id == record.control_objective_id &&
        another_record && !record.marked_for_destruction?
    end

    record.errors.add attr, :taken if is_duplicated
  end
  validates_each :controls do |record, attr, value|
    active_controls = value &&
      value.reject(&:marked_for_destruction?).size > 0

    record.errors.add attr, :blank unless active_controls
  end
  # Validaciones sólo ejecutadas cuando el objetivo es marcado como terminado
  validates_presence_of :audit_date, :relevance, :auditor_comment,
    :if => :finished
  validates_each :post_audit_qualification, :if => :finished do |record, attr, value|
    if value.blank? && record.pre_audit_qualification.blank?
      record.errors.add attr, :blank
    end
  end
  
  # Relaciones
  belongs_to :control_objective
  belongs_to :review
  has_many :weaknesses, :dependent => :destroy, :order => 'review_code ASC',
    :conditions => {:final => false}
  has_many :oportunities, :dependent => :destroy, :order => 'review_code ASC',
    :conditions => {:final => false}
  has_many :final_weaknesses, :dependent => :destroy, :class_name => 'Weakness',
    :order => 'review_code ASC', :conditions => {:final => true}
  has_many :final_oportunities, :dependent => :destroy,
    :order => 'review_code ASC', :class_name => 'Oportunity',
    :conditions => {:final => true}
  has_one :process_control, :through => :control_objective
  has_many :pre_audit_work_papers, :class_name => 'WorkPaper',
    :as => :owner, :dependent => :destroy, :order => 'created_at ASC',
    :before_add => [:check_for_final_review, :prepare_work_paper,
    :mark_as_pre_audit], :before_remove => :check_for_final_review,
    :conditions => {:work_paper_type => 'ControlObjectiveItemPreAudit'}
  has_many :post_audit_work_papers, :class_name => 'WorkPaper',
    :as => :owner, :dependent => :destroy, :order => 'created_at ASC',
    :before_add => [:check_for_final_review, :prepare_work_paper,
    :mark_as_post_audit], :before_remove => :check_for_final_review,
    :conditions => {:work_paper_type => 'ControlObjectiveItemPostAudit'}
  has_many :controls, :as => :controllable, :dependent => :destroy,
    :order => "#{Control.table_name}.order ASC"

  accepts_nested_attributes_for :controls, :allow_destroy => true
  accepts_nested_attributes_for :pre_audit_work_papers, :allow_destroy => true
  accepts_nested_attributes_for :post_audit_work_papers, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    if self.control_objective
      self.relevance ||= self.control_objective.relevance
    end

    self.finished ||= false
    self.controls.build if self.controls.blank?
  end

  def check_for_final_review(_)
    if self.review && self.review.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix = self.get_parameter(
      :admin_code_prefix_for_work_papers_in_control_objectives)
    work_paper.neighbours = (self.review.try(:work_papers) || []) +
      self.work_papers.reject { |wp| wp == work_paper }
  end

  def mark_as_pre_audit(work_paper)
    work_paper.work_paper_type = 'ControlObjectiveItemPreAudit'
  end

  def mark_as_post_audit(work_paper)
    work_paper.work_paper_type = 'ControlObjectiveItemPostAudit'
  end

  def <=>(other)
    if other && other.kind_of?(ControlObjectiveItem)
      bp_base = 2 ** 64
      pc_base = 2 ** 32
      
      order_1 = self.control_objective.process_control.best_practice_id *
        bp_base + self.control_objective.process_control.order * pc_base +
        self.control_objective.order
      order_2 = other.control_objective.process_control.best_practice_id *
        bp_base + other.control_objective.process_control.order * pc_base +
        other.control_objective.order

      order_1 <=> order_2
    else
      -1
    end
  end

  def effectiveness
    parameter_qualifications = self.get_parameter(
      :admin_control_objective_qualifications)
    highest_qualification =
      parameter_qualifications.map { |item| item[1].to_i }.max || 0
    qualifications = []

    if highest_qualification > 0
      if self.post_audit_qualification
        post_audit = self.post_audit_qualification * 100.0 /
          highest_qualification
        qualifications << post_audit.round
      end

      if self.pre_audit_qualification
        pre_audit = self.pre_audit_qualification * 100.0 /
          highest_qualification
        qualifications << pre_audit.round
      end
    end

    qualifications.empty? ? 100 :
      (qualifications.sum / qualifications.size).round
  end

  def fill_control_objective_text
    self.control_objective_text ||= self.control_objective.try(:name)
  end

  def work_papers
    self.pre_audit_work_papers + self.post_audit_work_papers
  end

  def must_be_approved?
    errors = []

    if !self.finished?
      errors << I18n.t(:'control_objective_item.errors.not_finished')
    end

    if !self.post_audit_qualification?
      errors << I18n.t(
        :'control_objective_item.errors.without_post_audit_quelification')
    end

    if self.relevance && self.relevance <= 0
      errors << I18n.t(:'control_objective_item.errors.without_relevance')
    end

    if self.audit_date.blank?
      errors << I18n.t(:'control_objective_item.errors.without_audit_date')
    end

    if self.controls.first.try(:effects).blank?
      errors << I18n.t(:'control_objective_item.errors.without_effects')
    end

    if self.controls.first.try(:control).blank?
      errors << I18n.t(
        :'control_objective_item.errors.without_controls')
    end

    if self.controls.first.try(:compliance_tests).blank?
      errors << I18n.t(
        :'control_objective_item.errors.without_compliance_tests')
    end

    if self.auditor_comment.blank?
      errors << I18n.t(:'control_objective_item.errors.without_auditor_comment')
    end

    if self.pre_audit_qualification &&
        self.controls.first.try(:design_tests).blank?
      errors << I18n.t(:'control_objective_item.errors.without_design_tests')
    end

    (@approval_errors = errors).blank?
  end

  def can_be_modified?
    unless self.is_in_a_final_review? && self.changed?
      true
    else
      msg = I18n.t(:'control_objective_item.readonly')
      self.errors.add_to_base msg unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def enable_control_validations
    if self.finished
      self.controls.each {|c| c.validates_presence_of_control = true}
      self.controls.each {|c| c.validates_presence_of_effects = true}

      if self.post_audit_qualification
        self.controls.each {|c| c.validates_presence_of_compliance_tests = true}
      end

      if self.pre_audit_qualification
        self.controls.each {|c| c.validates_presence_of_design_tests = true}
      end
    end
  end

  def can_be_destroyed?
    self.is_in_a_final_review? ? false : true
  end

  def is_in_a_final_review?
    self.review && self.review.has_final_review?
  end

  def relevance_text(show_value = false)
    relevances = self.get_parameter(:admin_control_objective_importances)
    relevance = relevances.detect { |r| r.last == self.relevance }

    relevance ? (show_value ? "#{relevance.first} (#{relevance.last})" :
        relevance.first) : ''
  end

  def pre_audit_qualification_text(show_value = false)
    post_audit_qualifications = self.get_parameter(
      :admin_control_objective_qualifications)
    pre_audit_qualification = post_audit_qualifications.detect do |r|
      r.last == self.pre_audit_qualification
    end

    pre_audit_qualification ? (show_value ?
        "#{pre_audit_qualification.first} (#{pre_audit_qualification.last})" :
        pre_audit_qualification.first) : ''
  end

  def post_audit_qualification_text(show_value = false)
    post_audit_qualifications = self.get_parameter(
      :admin_control_objective_qualifications)
    post_audit_qualification = post_audit_qualifications.detect do |r|
      r.last == self.post_audit_qualification
    end

    post_audit_qualification ? (show_value ?
        "#{post_audit_qualification.first} (#{post_audit_qualification.last})" :
        post_audit_qualification.first) : ''
  end

  def to_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)

    pdf.add_review_header organization, self.review.identification.strip,
      self.review.plan_item.project.strip

    pdf.move_pointer((PDF_FONT_SIZE * 2.5).round)

    pdf.add_description_item(ProcessControl.human_name,
      self.process_control.try(:name), 0, false, (PDF_FONT_SIZE * 1.25).round)
    pdf.add_description_item(ControlObjectiveItem.human_name,
      self.control_objective_text, 0, false, (PDF_FONT_SIZE * 1.25).round)

    pdf.move_pointer((PDF_FONT_SIZE * 2.5).round)

    pdf.add_description_item(ControlObjectiveItem.human_attribute_name(
        :relevance), self.relevance_text(true), 0, false)
    pdf.add_description_item(ControlObjectiveItem.human_attribute_name(
        :audit_date),
      (I18n.l(self.audit_date, :format => :long) if self.audit_date), 0, false)
    pdf.add_description_item(Control.human_attribute_name(:effects),
      self.controls.first.effects, 0, false)
    pdf.add_description_item(Control.human_attribute_name(:control),
      self.controls.first.control, 0, false)
    pdf.add_description_item(Control.human_attribute_name(:compliance_tests),
      self.controls.first.compliance_tests, 0, false)
    pdf.add_description_item(ControlObjectiveItem.human_attribute_name(
        :auditor_comment), self.auditor_comment, 0, false)
    pdf.add_description_item(ControlObjectiveItem.human_attribute_name(
        :post_audit_qualification), self.post_audit_qualification_text(true),
      0, false)
    pdf.add_description_item(ControlObjectiveItem.human_attribute_name(
        :effectiveness), "#{self.effectiveness}%", 0, false)

    unless self.work_papers.blank?
      pdf.start_new_page
      pdf.move_pointer PDF_FONT_SIZE * 3

      pdf.add_title(ControlObjectiveItem.human_attribute_name(:work_papers),
        (PDF_FONT_SIZE * 1.5).round, :center, false)

      pdf.move_pointer PDF_FONT_SIZE * 3

      self.work_papers.each do |wp|
        pdf.text wp.inspect, :justification => :center,
          :font_size => PDF_FONT_SIZE
      end
    else
      pdf.add_footnote(I18n.t(:'control_objective_item.without_work_papers'))
    end

    pdf.custom_save_as(self.pdf_name, ControlObjectiveItem.table_name,
      self.id)
  end

  def absolute_pdf_path
    PDF::Writer.absolute_path(self.pdf_name, ControlObjectiveItem.table_name,
      self.id)
  end

  def relative_pdf_path
    PDF::Writer.relative_path(self.pdf_name, ControlObjectiveItem.table_name,
      self.id)
  end

  def pdf_name
    "#{self.class.human_name.downcase.gsub(/\s/, '_')}-#{'%08d' % self.id}.pdf"
  end

  def pdf_column_data(finding, pc_id)
    body = String.new
    weakness = finding.kind_of?(Weakness)
    head = "<b>#{ControlObjective.human_name}:</b> " +
      "#{self.control_objective_text.chomp}\n"

    unless finding.review_code.blank?
      head << "<b>#{finding.class.human_attribute_name('review_code')}:</b> " +
        "#{finding.review_code.chomp}\n"
    end

    unless finding.description.blank?
      head << "<b>#{finding.class.human_attribute_name('description')}:</b> " +
        finding.description.chomp
    end

    if weakness && !finding.risk_text.blank?
      body << "<b>#{Weakness.human_attribute_name('risk')}:</b> " +
        "#{finding.risk_text.chomp}\n"
    end

    if weakness && !finding.effect.blank?
      body << "<b>#{Weakness.human_attribute_name('effect')}:</b> " +
        "#{finding.effect.chomp}\n"
    end

    if weakness && !finding.audit_recommendations.blank?
      body << "<b>#{Weakness.human_attribute_name('audit_recommendations')}: " +
        "</b>#{finding.audit_recommendations}\n"
    end

    unless finding.answer.blank?
      body << "<b>#{finding.class.human_attribute_name('answer')}:</b> " +
        "#{finding.answer.chomp}\n"
    end

    if weakness && !finding.implemented_audited?
      unless finding.follow_up_date.blank?
        body << "<b>#{Weakness.human_attribute_name('follow_up_date')}:</b> " +
          "#{I18n.l(finding.follow_up_date, :format => :long)}\n"
      end
    elsif !finding.solution_date.blank?
      body << "<b>#{finding.class.human_attribute_name('solution_date')}:"+
        "</b> #{I18n.l(finding.solution_date, :format => :long)}\n"
    end

    audited_users = finding.users.select { |u| u.can_act_as_audited? }

    unless audited_users.blank?
      body << "<b>#{finding.class.human_attribute_name('user_ids')}:</b> " +
        "#{audited_users.map { |u| u.full_name }.join('; ')}\n"
    end

    unless finding.audit_comments.blank?
      body << "<b>#{finding.class.human_attribute_name('audit_comments')}:" +
        "</b> #{finding.audit_comments.chomp}\n"
    end

    unless finding.state_text.blank?
      body << "<b>#{finding.class.human_attribute_name('state')}:</b> " +
        finding.state_text.chomp
    end

    [{ pc_id => head.to_iso }, { pc_id => body.to_iso }]
  end
end