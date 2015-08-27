class Review < ActiveRecord::Base
  include Parameters::Risk
  include Parameters::Score
  include ParameterSelector
  include Trimmer

  trimmed_fields :identification

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :period => {
      :column => "#{Period.quoted_table_name}.#{Period.qcn('number')}", :operator => '=', :mask => "%d",
      :conversion_method => :to_i, :regexp => /\A\s*\d+\s*\Z/
    },
    :identification => {
      :column => "LOWER(#{quoted_table_name}.#{qcn('identification')})", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :business_unit => {
      :column => "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('name')})", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn('project')})", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  # Callbacks
  before_validation :set_proper_parent, :can_be_modified?
  before_save :calculate_score
  before_destroy :can_be_destroyed?

  # Acceso a los atributos
  attr_reader :approval_errors, :control_objective_ids, :process_control_ids
  attr_accessor :can_be_approved_by_force, :control_objective_data,
    :process_control_data
  attr_readonly :plan_item_id

  # Named scopes
  scope :list, -> {
    where(organization_id: Organization.current_id).order(identification: :asc)
  }
  scope :list_with_approved_draft, -> {
    list.includes(:conclusion_draft_review).where(
      ConclusionReview.table_name => { approved: true }
    ).references(:conclusion_reviews)
  }
  scope :list_with_final_review, -> {
    list.includes(:conclusion_final_review).where(
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL"
    ).references(:conclusion_reviews)
  }
  scope :list_without_final_review, -> {
    list.includes(:conclusion_final_review).where(
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NULL"
    ).references(:conclusion_reviews)
  }
  scope :list_without_draft_review, -> {
    list.includes(:conclusion_draft_review).where(
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NULL"
    ).references(:conclusion_reviews)
  }
  scope :list_all_without_final_review_by_date, ->(from_date, to_date) {
    list.includes(
      :period, :conclusion_final_review, {
        :plan_item => {:business_unit => :business_unit_type}
      }
    ).where(
      [
        "#{quoted_table_name}.#{qcn('created_at')} BETWEEN :from_date AND :to_date",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('review_id')} IS NULL"
      ].join(' AND '),
      { :from_date => from_date, :to_date => to_date.to_time.end_of_day }
    ).order(
      [
        "#{Period.quoted_table_name}.#{Period.qcn('start')} ASC",
        "#{Period.quoted_table_name}.#{Period.qcn('end')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
        "#{quoted_table_name}.#{qcn('created_at')} ASC"
      ]
    ).references(:conclusion_reviews, :business_unit_types)
  }
  scope :list_all_without_workflow, ->(period_id) {
    list.includes(:workflow).list.where(
      [
        "#{quoted_table_name}.#{qcn('period_id')} = :period_id",
        "#{Workflow.quoted_table_name}.#{Workflow.qcn('review_id')} IS NULL"
      ].join(' AND '), { :period_id => period_id }
    ).references(:workflows)
  }
  scope :internal_audit, -> {
    includes(
      :plan_item => {:business_unit => :business_unit_type}
    ).where("#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn 'external'}" => false).references(
      :business_unit_types
    )
  }
  scope :external_audit, -> {
    includes(
      :plan_item => {:business_unit => :business_unit_type}
    ).where("#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn 'external'}" => true).references(
      :business_unit_types
    )
  }

  # Restricciones
  validates :identification, :format => {:with => /\A\w[\w\s-]*\z/},
    :allow_nil => true, :allow_blank => true
  validates :identification, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :identification, :description, :period_id, :plan_item_id,
    :organization_id, :presence => true
  validates :plan_item_id, :uniqueness => {:case_sensitive => false}
  validates :period_id, :plan_item_id, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates_each :identification do |record, attr, value|
    reviews = Review.list.where(
      [
        'identification = :identification',
        (record.id ? "#{quoted_table_name}.#{qcn('id')} <> :id" : "#{quoted_table_name}.#{qcn('id')} IS NOT NULL")
      ].join(' AND '), { :identification => value, :id => record.id }
    )
    record.errors.add attr, :taken if reviews.count > 0
  end
  validates_each :review_user_assignments do |record, attr, value|
    record.errors.add attr, :invalid unless Review.check_user_roles(record)
  end
  validates_each :plan_item_id do |record, attr, value|
    if value && !PlanItem.find_by(:id => value).try(:business_unit)
      record.errors.add attr, :invalid
    end
  end

  # Relaciones
  belongs_to :period
  belongs_to :plan_item
  belongs_to :file_model
  belongs_to :organization
  has_one :conclusion_draft_review, :dependent => :destroy
  has_one :conclusion_final_review
  has_one :business_unit, :through => :plan_item
  has_one :workflow, :dependent => :destroy
  has_many :control_objective_items, :dependent => :destroy, :after_add => :assign_review
  has_many :weaknesses, :through => :control_objective_items
  has_many :oportunities, :through => :control_objective_items
  has_many :fortresses, :through => :control_objective_items
  has_many :nonconformities, :through => :control_objective_items
  has_many :potential_nonconformities, :through => :control_objective_items
  has_many :final_weaknesses, :through => :control_objective_items
  has_many :final_fortresses, :through => :control_objective_items
  has_many :final_nonconformities, :through => :control_objective_items
  has_many :final_potential_nonconformities, :through => :control_objective_items
  has_many :final_oportunities, :through => :control_objective_items
  has_many :review_user_assignments, :dependent => :destroy
  has_many :finding_review_assignments, :dependent => :destroy,
    :inverse_of => :review, :after_add => :check_if_is_in_a_final_review
  has_many :users, :through => :review_user_assignments

  accepts_nested_attributes_for :review_user_assignments, :allow_destroy => true
  accepts_nested_attributes_for :finding_review_assignments, :allow_destroy => true
  accepts_nested_attributes_for :file_model, :allow_destroy => true
  accepts_nested_attributes_for :control_objective_items, :allow_destroy => true

  def to_s
    self.long_identification +
      " (#{I18n.l(self.issue_date, :format => :minimal)})"
  end

  def long_identification
    "#{self.identification} - #{self.plan_item.project}"
  end

  def assign_review(related_object)
    related_object.review = self
  end

  def set_proper_parent
    self.review_user_assignments.each { |rua| rua.review = self }
  end

  def self.check_user_roles(record)
    record.has_audited? && record.has_auditor? && record.has_supervisor? && record.has_manager? ||
    record.has_audited? && record.has_auditor? && record.has_manager? ||
    record.has_audited? && record.has_auditor? && record.has_supervisor?
  end

  def can_be_modified?
    if self.has_final_review? && self.changed?
      msg = I18n.t('review.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

      false
    else
      true
    end
  end

  def can_be_destroyed?
    !self.has_final_review? &&
      self.control_objective_items.all? { |coi| coi.can_be_destroyed? }
  end

  def has_final_review?
    self.conclusion_final_review
  end

  def is_frozen?
    self.has_final_review? && self.conclusion_final_review.is_frozen?
  end

  def check_if_is_in_a_final_review(finding_review_assignment)
    finding_review_assignment.finding.tap do |f|
      if f && !f.is_in_a_final_review?
        raise 'The finding must be in a final review'
      end
    end
  end

  def process_control_ids=(ids)
    (ids || []).uniq.each do |pc_id|
      if ProcessControl.exists?(pc_id)
        cois = []
        pc = ProcessControl.find(pc_id)
        control_objective_ids = control_objective_items.map(&:control_objective_id)

        pc.control_objectives.each do |co|
          if !co.obsolete && control_objective_ids.exclude?(co.id)
            cois << {
              :control_objective_id => co.id,
              :control_objective_text => co.name,
              :relevance => co.relevance,
              :control_attributes => {
                :control => co.control.control,
                :effects => co.control.effects,
                :design_tests => co.control.design_tests,
                :compliance_tests => co.control.compliance_tests,
                :sustantive_tests => co.control.sustantive_tests
              }
            }
          end
        end

        self.control_objective_items.build(cois) unless cois.empty?
      end
    end
  end

  def control_objective_ids=(ids)
    (ids || []).uniq.each do |co_id|
      if co_id.respond_to?(:to_i) && ControlObjective.exists?(co_id)
        co = ControlObjective.find co_id
        control_objective_ids = control_objective_items.map(&:control_objective_id)

        unless control_objective_ids.include?(co.id)
          control_objective_items.build(
            :control_objective_id => co.id,
            :control_objective_text => co.name,
            :relevance => co.relevance,
            :control_attributes => {
              :control => co.control.control,
              :effects => co.control.effects,
              :design_tests => co.control.design_tests,
              :compliance_tests => co.control.compliance_tests,
              :sustantive_tests => co.control.sustantive_tests
            }
          )
        end
      end
    end
  end

  def clone_from(other)
    self.attributes = other.attributes.merge(
      'id' => nil, 'period_id' => nil, 'plan_item_id' => nil,
      'identification' => nil, 'file_model_id' => nil)

    other.control_objective_items.each do |coi|
      self.control_objective_items.build(coi.attributes.merge(
          'id' => nil,
          'control_attributes' => coi.control.attributes.merge('id' => nil)
        )
      )
    end

    other.review_user_assignments.each do |rua|
      self.review_user_assignments.build(rua.attributes.merge('id' => nil))
    end
  end

  def internal_audit?
    !self.business_unit.business_unit_type.external
  end

  def external_audit?
    self.business_unit.business_unit_type.external
  end

  def calculate_score
    self.score_array # Recalcula score y asigna achieved_scale y top_scale
  end

  # Devuelve la calificación del informe, siempre es un arreglo de dos elementos
  # como sigue: ['nota en texto', integer_promedio], por ejemplo
  # ['Satisfactorio', 90]
  def score_array
    scores = self.class.scores.to_a
    count = scores.size + 1

    self.effectiveness # Recalcula score
    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }
    score_description = scores.detect {|s| count -= 1; self.score >= s[1].to_i}

    self.achieved_scale = count
    self.top_scale = scores.size

    [score_description ? score_description[0] : '-', self.score]
  end

  def score_text
    score = self.score_array

    score ? [I18n.t("score_types.#{score.first}"), "(#{score.last}%)"].join(' ') : ''
  end

  def control_objective_items_for_score
    self.control_objective_items.reject &:exclude_from_score
  end

  def effectiveness
    coi_count = self.control_objective_items_for_score.inject(0.0) do |acc, coi|
      acc + (coi.relevance || 0)
    end
    total = self.control_objective_items_for_score.inject(0.0) do |acc, coi|
      acc + coi.effectiveness * (coi.relevance || 0)
    end

    self.score = coi_count > 0 ? (total / coi_count.to_f).round : 100
  end

  def issue_date(include_draft = false)
    self.conclusion_final_review.try(:issue_date) ||
      (self.conclusion_draft_review.try(:issue_date) if include_draft) ||
      self.plan_item.start
  end

  def must_be_approved?
    errors = []
    review_errors = []
    self.can_be_approved_by_force = true

    if self.control_objective_items.empty?
      self.can_be_approved_by_force = false
      review_errors << I18n.t('review.errors.without_control_objectives')
    end

    self.control_objective_items.each do |coi|
      coi.weaknesses.each do |w|
        unless w.must_be_approved?
          self.can_be_approved_by_force = false
          errors << [
            "#{Weakness.model_name.human} #{w.review_code} - #{w.title}",
            w.approval_errors
          ]
        end
      end

      coi.weaknesses.select(&:unconfirmed?).each do |w|
        errors << [
          "#{Weakness.model_name.human} #{w.review_code} - #{w.title}",
          [I18n.t('weakness.errors.is_unconfirmed')]
        ]
      end

      coi.nonconformities.each do |nc|
        unless nc.must_be_approved?
          self.can_be_approved_by_force = false
          errors << [
            "#{Nonconformity.model_name.human} #{nc.review_code} - #{nc.title}",
            nc.approval_errors
          ]
        end
      end

      coi.nonconformities.select(&:unconfirmed?).each do |nc|
        errors << [
          "#{Nonconformity.model_name.human} #{nc.review_code} - #{nc.title}",
          [I18n.t('nonconformity.errors.is_unconfirmed')]
        ]
      end

      coi.oportunities.each do |o|
        unless o.must_be_approved?
          errors << [
            "#{Oportunity.model_name.human} #{o.review_code} - #{o.title}",
            o.approval_errors
          ]
        end
      end

      coi.potential_nonconformities.each do |p_nc|
        unless p_nc.must_be_approved?
          errors << [
            "#{PotentialNonconformity.model_name.human} #{p_nc.review_code} - #{p_nc.title}",
            p_nc.approval_errors
          ]
        end
      end

      unless coi.must_be_approved?
        self.can_be_approved_by_force = false
        errors << [
          "#{ControlObjectiveItem.model_name.human}: #{coi}", coi.approval_errors
        ]
      end
    end

    self.finding_review_assignments.each do |fra|
      if !fra.finding.repeated? && !fra.finding.implemented_audited?
        errors << [
          "#{Finding.model_name.human} #{fra.finding.review_code} - #{fra.finding.title} [#{fra.finding.review}]",
          [I18n.t('review.errors.related_finding_incomplete')]
        ]
      end
    end

    if self.survey.blank?
      review_errors << I18n.t('review.errors.without_survey')
    end

    errors << [Review.model_name.human, review_errors] unless review_errors.blank?

    (@approval_errors = errors).blank?
  end

  alias_method :is_approved?, :must_be_approved?
  alias_method :can_be_sended?, :must_be_approved?

  def has_audited?
    self.review_user_assignments.any? do |rua|
      rua.audited? && !rua.marked_for_destruction?
    end
  end

  def has_auditor?
    self.review_user_assignments.any? do |rua|
      rua.auditor? && !rua.marked_for_destruction?
    end
  end

  def has_manager?
    self.review_user_assignments.any? do |rua|
      rua.manager? && !rua.marked_for_destruction?
    end
  end

  def has_supervisor?
    self.review_user_assignments.any? do |rua|
      rua.supervisor? && !rua.marked_for_destruction?
    end
  end

  def last_control_objective_work_paper_code(prefix = nil)
    work_papers = []

    self.control_objective_items.each do |coi|
      work_papers.concat(coi.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def last_weakness_work_paper_code(prefix = nil)
    work_papers = []

    (self.weaknesses + self.final_weaknesses).each do |w|
      work_papers.concat(w.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def last_fortress_work_paper_code(prefix = nil)
    work_papers = []

    (self.fortresses + self.final_fortresses).each do |w|
      work_papers.concat(w.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def last_nonconformity_work_paper_code(prefix = nil)
    work_papers = []

    (self.nonconformities + self.final_nonconformities).each do |w|
      work_papers.concat(w.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def last_potential_nonconformity_work_paper_code(prefix = nil)
    work_papers = []

    (self.potential_nonconformities + self.final_potential_nonconformities).each do |w|
      work_papers.concat(w.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def last_oportunity_work_paper_code(prefix = nil)
    work_papers = []

    (self.oportunities + self.final_oportunities).each do |w|
      work_papers.concat(w.work_papers.with_prefix(prefix))
    end

    last_work_paper_code(prefix, work_papers)
  end

  def next_weakness_code(prefix = nil)
    next_finding_code prefix, self.weaknesses.with_prefix(prefix)
  end

  def next_fortress_code(prefix = nil)
    next_finding_code prefix, self.fortresses.with_prefix(prefix)
  end

  def next_nonconformity_code(prefix = nil)
    next_finding_code prefix, self.nonconformities.with_prefix(prefix)
  end

  def next_potential_nonconformity_code(prefix = nil)
    next_finding_code prefix, self.potential_nonconformities.with_prefix(prefix)
  end

  def next_oportunity_code(prefix = nil)
    next_finding_code prefix, self.oportunities.with_prefix(prefix)
  end

  def work_papers
    work_papers = []

    self.control_objective_items.each do |coi|
      work_papers.concat(coi.work_papers)
    end

    (self.oportunities + self.final_oportunities).each do |w|
      work_papers.concat(w.work_papers)
    end

    work_papers
  end

  def grouped_control_objective_items(options = {})
    grouped_control_objective_items = {}
    control_objective_items = options[:hide_excluded_from_score] ?
      self.control_objective_items.reject(&:exclude_from_score) :
      self.control_objective_items

    control_objective_items.each do |coi|
      grouped_control_objective_items[coi.process_control] ||= []

      unless grouped_control_objective_items[coi.process_control].include?(coi)
        grouped_control_objective_items[coi.process_control] << coi
      end
    end

    grouped_control_objective_items.to_a.sort do |gcoi1, gcoi2|
      pc1 = gcoi1.last.map(&:order_number).compact.min || -1
      pc2 = gcoi2.last.map(&:order_number).compact.min || -1

      pc1 <=> pc2
    end
  end

  def survey_pdf(organization = nil)
    pdf = Prawn::Document.create_generic_pdf(:portrait)

    pdf.add_review_header organization, self.identification.strip,
      self.plan_item.project.strip
    pdf.add_title Review.human_attribute_name 'survey'

    pdf.move_down PDF_FONT_SIZE

    pdf.text self.survey, :font_size => PDF_FONT_SIZE, :align => :justify

    pdf.move_down PDF_FONT_SIZE * 2

    note_text = self.file_model.try(:file?) ?
      I18n.t('review.survey.with_attachment') :
      I18n.t('review.survey.without_attachment')

    pdf.add_footnote "<i>#{note_text}</i>"

    pdf.custom_save_as self.survey_pdf_name, 'review_surveys', self.id
  end

  def absolute_survey_pdf_path
    Prawn::Document.absolute_path self.survey_pdf_name, 'review_surveys', self.id
  end

  def relative_survey_pdf_path
    Prawn::Document.relative_path self.survey_pdf_name, 'review_surveys', self.id
  end

  def survey_pdf_name
    identification = self.identification
    survey = Review.human_attribute_name(:survey).downcase

    "#{survey}-#{identification}.pdf".sanitized_for_filename
  end

  def score_sheet(organization = nil, draft = false)
    pdf = self.score_sheet_common_header organization, false, draft

    pdf.move_down PDF_FONT_SIZE

    column_headers, column_widths, column_data = [], [], []
    process_controls = {}

    column_headers << ''
    column_widths << pdf.percent_width(70)

    column_headers << I18n.t('review.control_objectives_relevance')
    column_widths << pdf.percent_width(15)

    column_headers << I18n.t('review.control_objectives_effectiveness')
    column_widths << pdf.percent_width(15)

    self.control_objective_items.each do |coi|
      process_controls[coi.process_control.name] ||= []
      process_controls[coi.process_control.name] << [
        coi.to_s, coi.effectiveness || 0, coi.relevance || 0, coi.exclude_from_score
      ]
    end

    column_data << [
      "<b>#{Review.model_name.human}</b> ",
      '',
      "<b>#{self.score}%</b>*"
    ]

    process_controls.each do |process_control, coi_data|
      coi_relevance_count = coi_data.inject(0) do |t, e|
        e[3] ? t : t + e[2]
      end.to_f
      effectiveness_average = coi_data.inject(0) do |t, e|
        coi_relevance_count > 0 ?
          e[3] ? t : t + (e[1] * e[2])  / coi_relevance_count : 100
      end
      exclude_from_score = coi_data.all? { |e| e[3] }

      column_data << [
        "#{ProcessControl.model_name.human}: #{process_control}",
        '',
        exclude_from_score ? '-' : "#{effectiveness_average.round}%**"
      ]

      coi_data.each do |coi|
        column_data << [
          "        • <i>#{ControlObjectiveItem.model_name.human}: " +
            "#{coi[0]}</i>",
          coi[3] ? '-' : "<i>#{coi[2]}</i>",
          coi[3] ? '-' : "<i>#{coi[1].round}%</i>"
        ]
      end
    end

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf.move_down((PDF_FONT_SIZE * 0.75).round)
    pdf.font_size((PDF_FONT_SIZE * 0.6).round) do
      pdf.text "<b>#{I18n.t('review.notes')}</b>:",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :inline_format => true
      pdf.text "<i>* #{I18n.t('review.review_qualification_explanation')}</i>",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :align => :justify,
        :inline_format => true
      pdf.text(
        "<i>** #{I18n.t('review.process_control_qualification_explanation')}</i>",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :align => :justify,
        :inline_format => true)
    end
    weaknesses = self.final_weaknesses.all_for_report

    unless weaknesses.blank?
      risk_levels_text = RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map do |r|
        I18n.t("risk_types.#{r[0]}")
      end.join(', ')
      pdf.add_subtitle I18n.t('review.weaknesses_summary',
        :risks => risk_levels_text), PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [['description', 60], ['risk', 15], ['state', 25]]

      column_names.each do |col_name, col_size|
        column_headers << Weakness.human_attribute_name(col_name)
        column_widths << pdf.percent_width(col_size)
      end

      weaknesses.each do |weakness|
        column_data << [
          "<b>#{weakness.review_code}</b>: #{weakness.title}",
          weakness.risk_text,
          weakness.state_text
        ]
      end

      unless column_data.blank?
       pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
          end
        end
      end
    end

    nonconformities = self.final_nonconformities.all_for_report

    unless nonconformities.blank?
      pdf.add_subtitle I18n.t('review.nonconformities_summary'), PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [['description', 60], ['risk', 15], ['state', 25]]

      column_names.each do |col_name, col_size|
        column_headers << Nonconformity.human_attribute_name(col_name)
        column_widths << pdf.percent_width(col_size)
      end

      nonconformities.each do |nonconformity|
        column_data << [
          "<b>#{nonconformity.review_code}</b>: #{nonconformity.title}",
          nonconformity.risk_text,
          nonconformity.state_text
        ]
      end

      unless column_data.blank?
       pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
          end
        end
      end
    end

    oportunities = self.final_oportunities.all_for_report

    unless oportunities.blank?
      pdf.add_subtitle I18n.t('review.oportunities_summary'), PDF_FONT_SIZE,
        PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [['description', 75], ['state', 25]]

      column_names.each do |col_name, col_size|
        column_headers << Oportunity.human_attribute_name(col_name)
        column_widths << pdf.percent_width(col_size)
      end

      oportunities.each do |oportunity|
        column_data << [
          "<b>#{oportunity.review_code}</b>: #{oportunity.title}",
          oportunity.state_text
        ]
      end

      unless column_data.blank?
       pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    potential_nonconformities = self.final_potential_nonconformities.all_for_report

    unless potential_nonconformities.blank?
      pdf.add_subtitle I18n.t('review.potential_nonconformities_summary'), PDF_FONT_SIZE,
        PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [['description', 75], ['state', 25]]

      column_names.each do |col_name, col_size|
        column_headers << PotentialNonconformity.human_attribute_name(col_name)
        column_widths << pdf.percent_width(col_size)
      end

      potential_nonconformities.each do |potential_nonconformity|
        description = "<b>#{potential_nonconformity.review_code}</b>: "
        description << "#{potential_nonconformity.title}"

        column_data << [
          description,
          potential_nonconformity.state_text
        ]
      end

      unless column_data.blank?
       pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    fortresses = self.final_fortresses.all_for_report

    unless fortresses.blank?
      pdf.add_subtitle I18n.t('review.fortresses_summary'), PDF_FONT_SIZE,
        PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [['description', 75]]

      column_names.each do |col_name, col_size|
        column_headers << Fortress.human_attribute_name(col_name)
        column_widths << pdf.percent_width(col_size)
      end

      fortresses.each do |fortress|
        column_data << ["<b>#{fortress.review_code}</b>: #{fortress.title}"]
      end

      unless column_data.blank?
       pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_review_auditors_table(
      self.review_user_assignments.reject { |rua| rua.audited? })

    pdf.custom_save_as(self.score_sheet_name, 'score_sheets', self.id)
  end

  def global_score_sheet(organization = nil, draft = false)
    pdf = self.score_sheet_common_header organization, true, draft

    pdf.move_down PDF_FONT_SIZE

    column_headers, column_widths, column_data = [], [], []
    process_controls = {}

    column_headers << ''
    column_widths << pdf.percent_width(70)

    column_headers << I18n.t('review.control_objectives_effectiveness')
    column_widths << pdf.percent_width(30)

    self.control_objective_items.each do |coi|
      process_controls[coi.process_control.name] ||= []
      process_controls[coi.process_control.name] << [
        coi.to_s, coi.effectiveness || 0, coi.relevance || 0, coi.exclude_from_score
      ]
    end

    column_data << [
      "<b>#{Review.model_name.human}</b>",
      "<b>#{self.score}%</b>*"
    ]

    process_controls.each do |process_control, coi_data|
      coi_relevance_count = coi_data.inject(0) do |t, e|
        e[3] ? t : t + e[2]
      end.to_f
      effectiveness_average = coi_data.inject(0) do |t, e|
        coi_relevance_count > 0 ?
          e[3] ? t : t + (e[1] * e[2]) / coi_relevance_count : 100
      end
      exclude_from_score = coi_data.all? { |e| e[3] }

      column_data << [
        "#{ProcessControl.model_name.human}: #{process_control}",
        exclude_from_score ? '-' : "#{effectiveness_average.round}%**"
      ]
    end

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf.move_down((PDF_FONT_SIZE * 0.75).round)

    pdf.font_size((PDF_FONT_SIZE * 0.6).round) do
      pdf.text "<b>#{I18n.t('review.notes')}</b>:",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :inline_format => true
      pdf.text "<i>* #{I18n.t('review.review_qualification_explanation')}</i>",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :align => :justify,
        :inline_format => true
      pdf.text(
        "<i>** #{I18n.t('review.process_control_qualification_explanation')}</i>",
        :font_size => (PDF_FONT_SIZE * 0.75).round, :align => :justify,
        :inline_format => true)
    end

    weaknesses = self.final_weaknesses.all_for_report

    unless weaknesses.blank?
      risk_levels_text = RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map do |r|
        I18n.t("risk_types.#{r[0]}")
      end.join(', ')
      pdf.add_subtitle I18n.t('review.weaknesses_count_summary',
        :risks => risk_levels_text), PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [
        I18n.t('review.weaknesses_count'),
        Weakness.human_attribute_name(:risk),
        Weakness.human_attribute_name(:state)
      ]

      column_names.each do |col_name|
        column_headers << col_name
        column_widths << pdf.percent_width(100.0 / column_names.size)
      end

      weakness = weaknesses.first
      risk_text, state_text = weakness.risk_text, weakness.state_text
      count = 0

      weaknesses.each do |w|
        if risk_text == w.risk_text && state_text == w.state_text
          count += 1
        else
          column_data << [
            count,
            risk_text,
            state_text
          ]

          risk_text, state_text = w.risk_text, w.state_text
          count = 1
        end
      end

      if count > 0
        column_data << [
          count,
          risk_text,
          state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    pdf.move_down PDF_FONT_SIZE

    nonconformities = self.final_nonconformities.all_for_report

    unless nonconformities.blank?
      pdf.add_subtitle I18n.t('review.nonconformities_count_summary', PDF_FONT_SIZE, PDF_FONT_SIZE)

      column_headers, column_widths, column_data = [], [], []
      column_names = [
        I18n.t('review.nonconformities_count'),
        Nonconformity.human_attribute_name(:risk),
        Nonconformity.human_attribute_name(:state)
      ]

      column_names.each do |col_name|
        column_headers << col_name
        column_widths << pdf.percent_width(100.0 / column_names.size)
      end

      nonconformity = nonconformities.first
      risk_text, state_text = nonconformity.risk_text, nonconformity.state_text
      count = 0

      nonconformities.each do |nc|
        if risk_text == nc.risk_text && state_text == nc.state_text
          count += 1
        else
          column_data << [
            count,
            risk_text,
            state_text
          ]

          risk_text, state_text = nc.risk_text, nc.state_text
          count = 1
        end
      end

      if count > 0
        column_data << [
          count,
          risk_text,
          state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    oportunities = self.final_oportunities.all_for_report

    unless oportunities.blank?
      risk_levels_text = RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map do |r|
        I18n.t("risk_types.#{r[0]}")
      end.join(', ')
      pdf.add_subtitle I18n.t('review.oportunities_count_summary'),
        PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [
        Oportunity.human_attribute_name(:count),
        Oportunity.human_attribute_name(:state)
      ]

      column_names.each do |col_name|
        column_headers << col_name
        column_widths << pdf.percent_width(100.0 / column_names.size)
      end

      oportunity = oportunities.first
      state_text = oportunity.state_text
      count = 0

      oportunities.each do |o|
        if state_text == o.state_text
          count += 1
        else
          column_data << [
            count,
            state_text
          ]

          state_text = o.state_text
          count = 1
        end
      end

      if count > 0
        column_data << [
          count,
          state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    potential_nonconformities = self.final_potential_nonconformities.all_for_report

    unless potential_nonconformities.blank?
      pdf.add_subtitle I18n.t('review.potential_nonconformities_count_summary'),
        PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [
        PotentialNonconformity.human_attribute_name(:count),
        PotentialNonconformity.human_attribute_name(:state)
      ]

      column_names.each do |col_name|
        column_headers << col_name
        column_widths << pdf.percent_width(100.0 / column_names.size)
      end

      potential_nonconformity = potential_nonconformities.first
      state_text = potential_nonconformity.state_text
      count = 0

      potential_nonconformities.each do |pnc|
        if state_text == pnc.state_text
          count += 1
        else
          column_data << [
            count,
            state_text
          ]

          state_text = pnc.state_text
          count = 1
        end
      end

      if count > 0
        column_data << [
          count,
          state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    fortresses = self.final_fortresses.all_for_report

    unless fortresses.blank?
      pdf.add_subtitle I18n.t('review.fortresses_count_summary'),
        PDF_FONT_SIZE, PDF_FONT_SIZE

      column_headers, column_widths, column_data = [], [], []
      column_names = [
        Fortress.human_attribute_name(:count)
      ]

      column_names.each do |col_name|
        column_headers << col_name
        column_widths << pdf.percent_width(100.0 / column_names.size)
      end

      fortress = fortresses.first
      state_text = fortress.state_text
      count = 0

      fortresses.each do |f|
        if state_text == f.state_text
          count += 1
        else
          column_data << [
            count
          ]

          count = 1
        end
      end

      if count > 0
        column_data << [
          count
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
         table_options = pdf.default_table_options(column_widths)

         pdf.table(column_data.insert(0, column_headers), table_options) do
           row(0).style(
             :background_color => 'cccccc',
             :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
           )
         end
       end
      end
    end

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_review_auditors_table(
      self.review_user_assignments.select { |rua| !rua.audited? })

    pdf.custom_save_as(self.global_score_sheet_name, 'global_score_sheets',
      self.id)
  end

  def score_sheet_common_header(organization = nil, global = false,
      draft = false)
    pdf = Prawn::Document.create_generic_pdf(:portrait)

    pdf.add_review_header organization, self.identification,
      self.plan_item.project
    pdf.add_title(global ? I18n.t('review.global_score_sheet_title') :
        I18n.t('review.score_sheet_title'))

    pdf.add_watermark(I18n.t('pdf.draft')) if draft

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      self.business_unit.business_unit_type.business_unit_label,
      self.business_unit.name)

    unless self.business_unit.business_unit_type.project_label.blank?
      pdf.add_description_item(
        self.business_unit.business_unit_type.project_label,
        self.plan_item.project)
    end

    pdf.add_description_item(
      I18n.t('review.audit_period_title'),
      I18n.t('review.audit_period',
        :start => I18n.l(self.plan_item.start, :format => :long),
        :end => I18n.l(self.plan_item.end, :format => :long)
      )
    )

    users = self.review_user_assignments.reject { |rua| rua.audited? }
    pdf.add_description_item(I18n.t('review.auditors'),
      users.map { |rua| rua.user.full_name }.join('; '))

    pdf.add_subtitle I18n.t('review.score'), PDF_FONT_SIZE, PDF_FONT_SIZE

    self.add_score_details_table(pdf)

    pdf
  end

  def add_score_details_table(pdf)
    scores = self.class.scores.to_a
    review_score = self.score_array.first
    columns = {}
    column_data = []
    column_headers, column_widths = [], []

    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }

    scores.each_with_index do |score, i|
      min_percentage = score[1]
      max_percentage = i > 0 && scores[i - 1] ? scores[i - 1][1] - 1 : 100
      column_text = I18n.t("score_types.#{score[0]}")

      column_headers << (score[0] != review_score ? column_text :
            "<b>#{column_text.upcase} (#{self.score}%)</b>"
        )

      column_widths << pdf.percent_width(100.0 / scores.size)

      column_data << "#{max_percentage}% - #{min_percentage}%"
    end

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table([column_data].insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
  end

  def absolute_score_sheet_path
    Prawn::Document.absolute_path(self.score_sheet_name, 'score_sheets', self.id)
  end

  def relative_score_sheet_path
    Prawn::Document.relative_path(self.score_sheet_name, 'score_sheets', self.id)
  end

  def score_sheet_name
    identification = self.sanitized_identification

    "#{I18n.t('review.score_sheet_filename')}-#{identification}.pdf"
  end

  def absolute_global_score_sheet_path
    Prawn::Document.absolute_path(self.global_score_sheet_name,
      'global_score_sheets', self.id)
  end

  def relative_global_score_sheet_path
    Prawn::Document.relative_path(self.global_score_sheet_name,
      'global_score_sheets', self.id)
  end

  def global_score_sheet_name
    identification = self.sanitized_identification

    "#{I18n.t('review.global_score_sheet_filename')}-#{identification}.pdf"
  end

  def sanitized_identification
    self.identification.strip.sanitized_for_filename
  end

  def zip_all_work_papers(organization = nil)
    filename = self.absolute_work_papers_zip_path
    weaknesses, oportunities, nonconformities, potential_nonconformities,
      fortresses, findings = [], [], [], [], [], []
    dirs = {
      :control_objectives => I18n.t('review.control_objectives_work_papers').sanitized_for_filename,
      :fortresses => I18n.t('review.fortresses_work_papers').sanitized_for_filename,
      :nonconformities => I18n.t('review.nonconformities_work_papers').sanitized_for_filename,
      :weaknesses => I18n.t('review.weaknesses_work_papers').sanitized_for_filename,
      :potential_nonconformities => I18n.t('review.potential_nonconformities_work_papers').sanitized_for_filename,
      :oportunities => I18n.t('review.oportunities_work_papers').sanitized_for_filename,
      :follow_up => I18n.t('review.follow_up_work_papers').sanitized_for_filename,
      :survey => Review.human_attribute_name(:survey).sanitized_for_filename
    }

    FileUtils.rm filename if File.exists?(filename)
    FileUtils.makedirs File.dirname(filename)

    Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
      self.control_objective_items.each do |coi|
        coi.work_papers.each do |pa_wp|
          self.add_work_paper_to_zip pa_wp, dirs[:control_objectives], zipfile
        end
      end

      if self.has_final_review?
        weaknesses = self.final_weaknesses.not_revoked
        oportunities = self.final_oportunities.not_revoked
        fortresses = self.final_fortresses.not_revoked
        nonconformities = self.final_nonconformities.not_revoked
        potential_nonconformities = self.final_potential_nonconformities.not_revoked
        findings = self.weaknesses.not_revoked +
          self.oportunities.not_revoked +
          self.fortresses.not_revoked +
          self.nonconformities.not_revoked +
          self.potential_nonconformities.not_revoked
      else
        weaknesses = self.weaknesses.not_revoked
        oportunities = self.oportunities.not_revoked
        fortresses = self.fortresses.not_revoked
        nonconformities = self.nonconformities.not_revoked
        potential_nonconformities = self.potential_nonconformities.not_revoked
        findings = []
      end

      fortresses.each do |f|
        f.work_papers.each do |f_wp|
          self.add_work_paper_to_zip f_wp, dirs[:fortresses], zipfile, 'E_'
        end
      end

      nonconformities.each do |nc|
        nc.work_papers.each do |nc_wp|
          self.add_work_paper_to_zip nc_wp, dirs[:nonconformities], zipfile, 'E_'
        end
      end

      potential_nonconformities.each do |pnc|
        pnc.work_papers.each do |pnc_wp|
          self.add_work_paper_to_zip pnc_wp, dirs[:potential_nonconformities], zipfile, 'E_'
        end
      end

      weaknesses.each do |w|
        w.work_papers.each do |w_wp|
          self.add_work_paper_to_zip w_wp, dirs[:weaknesses], zipfile, 'E_'
        end
      end

      oportunities.each do |o|
        o.work_papers.each do |o_wp|
          self.add_work_paper_to_zip o_wp, dirs[:oportunities], zipfile, 'E_'
        end
      end

      findings.each do |f|
        f.work_papers.each do |f_wp|
          self.add_work_paper_to_zip f_wp, dirs[:follow_up], zipfile, 'S_'
        end
      end

      if self.file_model.try(:file?)
        self.add_file_to_zip self.file_model.file.path,
          self.file_model.identifier, dirs[:survey], zipfile
      end

      unless self.survey.blank?
        self.survey_pdf organization

        self.add_file_to_zip(self.absolute_survey_pdf_path,
          self.survey_pdf_name, dirs[:survey], zipfile)
      end
    end

    FileUtils.chmod 0640, filename
  end

  def absolute_work_papers_zip_path
    File.join PRIVATE_PATH, self.work_papers_zip_path
  end

  def relative_work_papers_zip_path
    "/private/#{self.work_papers_zip_path}"
  end

  def work_papers_zip_path
    filename_prefix = Review.human_attribute_name(:work_papers).downcase.sanitized_for_filename
    path = ('%08d' % (Organization.current_id || 0)).scan(/\d{4}/) +
      [Review.table_name] + ('%08d' % self.id).scan(/\d{4}/) +
      ["#{filename_prefix}-#{self.sanitized_identification}.zip"]

    File.join *path
  end

  def add_work_paper_to_zip(wp, dir, zipfile, prefix = nil)
    if wp.file_model.try(:file?) && File.exist?(wp.file_model.file.path)
      self.add_file_to_zip(wp.file_model.file.path,
        wp.file_model.identifier, dir, zipfile)
    else
      identification = "#{prefix}#{self.sanitized_identification}"
      wp.create_pdf_cover(identification, self)

      self.add_file_to_zip(wp.absolute_cover_path(identification),
        wp.pdf_cover_name(identification), dir, zipfile)
    end
  end

  def add_file_to_zip(file_path, zip_filename, zip_dir, zipfile)
    zip_filename = File.join zip_dir, zip_filename.sanitized_for_filename

    zipfile.add(zip_filename, file_path) { true } if File.exist?(file_path)
  end

  private

  def last_work_paper_code(prefix, work_papers)
    last_code = work_papers.map do |wp|
      wp.code.match(/\d+\Z/)[0].to_i if wp.code =~ /\d+\Z/
    end.compact.sort.last

    last_number = last_code.blank? ? 0 : last_code

    "#{prefix} #{'%.2d' % last_number}".strip
  end

  def next_finding_code(prefix, findings)
    last_review_code = findings.order(:review_code => :asc).last.try(:review_code)
    last_number = (last_review_code || '0').match(/\d+\Z/)[0].to_i || 0

    raise 'A review can not have more than 999 findings' if last_number > 999

    "#{prefix}#{'%.3d' % last_number.next}".strip
  end
end
