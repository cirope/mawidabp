class Review < ActiveRecord::Base
  include ParameterSelector
  include Trimmer

  trimmed_fields :identification
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :period => {
      :column => "#{Period.table_name}.number", :operator => '=', :mask => "%d",
      :conversion_method => :to_i, :regexp => /\A\s*\d+\s*\Z/
    },
    :identification => {
      :column => "LOWER(#{table_name}.identification)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :business_unit => {
      :column => "LOWER(#{BusinessUnit.table_name}.name)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.table_name}.project)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  # Callbacks
  before_validation :set_proper_parent#, :can_be_modified?
  before_destroy :can_be_destroyed?

  # Acceso a los atributos
  attr_reader :approval_errors, :procedure_control_subitem_ids
  attr_accessor :can_be_approved_by_force, :procedure_control_subitem_data
  attr_readonly :plan_item_id
  
  # Named scopes
  scope :list, lambda {
    {
      :include => :period,
      :conditions => {
        "#{Period.table_name}.organization_id" =>
          GlobalModelConfig.current_organization_id
      },
      :order => 'identification ASC'
    }
  }
  scope :list_with_approved_draft, lambda {
    {
      :include => [:period, :conclusion_draft_review],
      :conditions => {
        ConclusionReview.table_name => {:approved => true},
        Period.table_name => {
          :organization_id => GlobalModelConfig.current_organization_id
        }
      },
      :order => 'identification ASC'
    }
  }
  scope :list_with_final_review, lambda {
    {
      :include => [:period, :conclusion_final_review],
      :conditions => [
        [
          "#{Period.table_name}.organization_id = :organization_id",
          "#{ConclusionReview.table_name}.review_id IS NOT NULL"
        ].join(' AND '),
        { :organization_id => GlobalModelConfig.current_organization_id }
      ],
      :order => 'identification ASC'
    }
  }
  scope :list_without_final_review, lambda {
    {
      :include => [:period, :conclusion_final_review],
      :conditions => [
        [
          "#{Period.table_name}.organization_id = :organization_id",
          "#{ConclusionReview.table_name}.review_id IS NULL"
        ].join(' AND '),
        { :organization_id => GlobalModelConfig.current_organization_id }
      ],
      :order => 'identification ASC'
    }
  }
  scope :list_without_draft_review, lambda {
    {
      :include => [:period, :conclusion_draft_review],
      :conditions => [
        [
          "#{Period.table_name}.organization_id = :organization_id",
          "#{ConclusionReview.table_name}.review_id IS NULL"
        ].join(' AND '),
        { :organization_id => GlobalModelConfig.current_organization_id }
      ],
      :order => 'identification ASC'
    }
  }
  scope :list_all_without_final_review_by_date, lambda { |from_date, to_date|
    {
      :include => [:period, :conclusion_final_review,
        {:plan_item => {:business_unit => :business_unit_type}}],
      :conditions => [
        [
          "#{Period.table_name}.organization_id = :organization_id",
          "#{table_name}.created_at BETWEEN :from_date AND :to_date",
          "#{ConclusionFinalReview.table_name}.review_id IS NULL"
        ].join(' AND '),
        {
          :from_date => from_date, :to_date => to_date.to_time.end_of_day,
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => [
        "#{Period.table_name}.start ASC",
        "#{Period.table_name}.end ASC",
        "#{BusinessUnitType.table_name}.external ASC",
        "#{BusinessUnitType.table_name}.name ASC",
        "#{table_name}.created_at ASC"
      ].join(', ')
    }
  }
  scope :list_all_without_workflow, lambda { |period_id|
    {
      :include => [:period, :workflow],
      :conditions => [
          [
            "#{Period.table_name}.organization_id = :organization_id",
            "#{table_name}.period_id = :period_id",
            "#{Workflow.table_name}.review_id IS NULL"
          ].join(' AND '),
          {
            :organization_id => GlobalModelConfig.current_organization_id,
            :period_id => period_id
          }
        ],
        :order => "#{table_name}.identification ASC"
    }
  }
  scope :internal_audit,
    :include => { :plan_item => {:business_unit => :business_unit_type} },
    :conditions => { "#{BusinessUnitType.table_name}.external" => false }
  scope :external_audit,
    :include => { :plan_item => {:business_unit => :business_unit_type} },
    :conditions => { "#{BusinessUnitType.table_name}.external" => true }

  # Restricciones
  validates_format_of :identification, :with => /\A\w[\w\s]*\z/,
    :allow_nil => true, :allow_blank => true
  validates_length_of :identification, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_presence_of :identification, :description, :period_id, :plan_item_id
  validates_uniqueness_of :identification, :plan_item_id,
    :case_sensitive => false
  validates_numericality_of :period_id, :plan_item_id, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validates_each :review_user_assignments do |record, attr, value|
    unless record.has_audited? && record.has_auditor? &&
        record.has_supervisor? && record.has_manager?
      record.errors.add attr, :invalid
    end
  end
  validates_each :plan_item do |record, attr, value|
    record.errors.add attr, :invalid if value && !value.business_unit
  end

  # Relaciones
  belongs_to :period
  belongs_to :plan_item
  belongs_to :file_model
  has_one :organization, :through => :period
  has_one :conclusion_draft_review
  has_one :conclusion_final_review
  has_one :business_unit, :through => :plan_item
  has_one :workflow, :dependent => :destroy
  has_many :control_objective_items, :dependent => :destroy,
    :after_add => :assign_review
  has_many :weaknesses, :through => :control_objective_items, :uniq => true
  has_many :oportunities, :through => :control_objective_items, :uniq => true
  has_many :final_weaknesses, :through => :control_objective_items,
    :uniq => true
  has_many :final_oportunities, :through => :control_objective_items,
    :uniq => true
  has_many :review_user_assignments, :dependent => :destroy, :include => :user,
    :order => 'assignment_type DESC'
  has_many :users, :through => :review_user_assignments, :uniq => true

  accepts_nested_attributes_for :review_user_assignments, :allow_destroy => true
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

  def can_be_modified?
    unless self.has_final_review? && self.changed?
      true
    else
      msg = I18n.t(:'review.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def can_be_destroyed?
    !self.has_final_review? &&
      self.control_objective_items.all? { |coi| coi.can_be_destroyed? }
  end

  def has_final_review?
    self.conclusion_final_review != nil
  end

  def is_frozen?
    self.has_final_review? && self.conclusion_final_review.is_frozen?
  end

  def procedure_control_subitem_ids=(ids)
    (ids || []).uniq.each do |pcs_id|
      if pcs_id.respond_to?(:to_i) &&
          ProcedureControlSubitem.exists?(pcs_id.to_i)
        pcs = ProcedureControlSubitem.find(pcs_id)
        control_objective_ids = self.control_objective_items.map(
          &:control_objective_id)

        unless control_objective_ids.include?(pcs.control_objective_id)
          self.control_objective_items.build(
            :control_objective_id => pcs.control_objective_id,
            :control_objective_text => pcs.control_objective_text,
            :controls_attributes => {
              :new_1 => {
                :control => pcs.controls.first.control,
                :effects => pcs.controls.first.effects,
                :design_tests => pcs.controls.first.design_tests,
                :compliance_tests => pcs.controls.first.compliance_tests
              }
            }
          )
        end
      end
    end
  end

  def clone_from(other)
    self.attributes = other.attributes.merge(
      :id => nil, :period_id => nil, :plan_item_id => nil,
      :identification => nil)

    other.control_objective_items.each do |coi|
      self.control_objective_items.build(coi.attributes.merge({
            :id => nil,
            :controls_attributes =>
              coi.controls.map { |c| c.attributes.merge :id => nil }
          }
        )
      )
    end

    other.review_user_assignments.each do |rua|
      self.review_user_assignments.build(rua.attributes.merge(:id => nil))
    end
  end

  def internal_audit?
    !self.business_unit.business_unit_type.external
  end

  def external_audit?
    self.business_unit.business_unit_type.external
  end

  # Devuelve la calificación del informe, siempre es un arreglo de dos elementos
  # como sigue: ['nota en texto', integer_promedio], por ejemplo
  # ['Satisfactorio', 90]
  def score
    average = self.effectiveness
    scores = parameter_in(GlobalModelConfig.current_organization_id,
      :admin_review_scores, self.created_at)
    
    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }
    score = scores.detect { |s| average >= s[1].to_i }

    [score ? score[0] : '-', average]
  end

  def score_text
    score = self.score

    "#{score.first} (#{score.last}%)"
  end

  def effectiveness
    coi_count = self.control_objective_items.inject(0.0) do |acc, coi|
      acc + (coi.relevance || 0)
    end
    total = self.control_objective_items.inject(0.0) do |acc, coi|
      acc + coi.effectiveness * (coi.relevance || 0)
    end

    coi_count > 0 ? (total / coi_count.to_f).round : 100
  end

  def issue_date(include_draft = false)
    self.conclusion_final_review.try(:issue_date) ||
      (self.conclusion_draft_review.try(:issue_date) if include_draft) ||
      self.created_at.to_date
  end

  def must_be_approved?(with_notifications = true)
    errors = []
    review_errors = []
    self.can_be_approved_by_force = true

    if self.control_objective_items.empty?
      self.can_be_approved_by_force = false
      review_errors << I18n.t(:'review.errors.without_control_objectives')
    end

    self.control_objective_items.each do |coi|
      coi.weaknesses.each do |w|
        unless w.must_be_approved?
          self.can_be_approved_by_force = false
          errors << [
            "#{Weakness.model_name.human} #{w.review_code}", w.approval_errors
          ]
        end
      end

      unless coi.must_be_approved?
        self.can_be_approved_by_force = false
        errors << [
          "#{ControlObjectiveItem.model_name.human}: #{coi.control_objective_text}",
          coi.approval_errors
        ]
      end
    end

    if with_notifications && self.conclusion_draft_review &&
        !self.conclusion_draft_review.notifications_approved?
      review_errors << I18n.t(:'review.errors.notifications_not_approved')
    end
    
    if self.survey.blank?
      review_errors << I18n.t(:'review.errors.without_survey')
    end

    errors << ["#{Review.model_name.human}", review_errors] unless review_errors.blank?

    (@approval_errors = errors).blank?
  end

  alias_method :is_approved?, :must_be_approved?

  def can_be_sended?
    conclusion_review = self.conclusion_final_review ||
        self.conclusion_draft_review
    notifications_rejected = conclusion_review.try(:notifications_rejected?)

    self.must_be_approved? ||
      (conclusion_review.try(:last_notifications).try(:empty?) ||
        notifications_rejected)
  end

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
      work_papers.concat(coi.post_audit_work_papers.with_prefix(prefix) +
          coi.pre_audit_work_papers.with_prefix(prefix))
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

  def next_oportunity_code(prefix = nil)
    next_finding_code prefix, self.oportunities.with_prefix(prefix)
  end

  def work_papers
    work_papers = []

    self.control_objective_items.each do |coi|
      work_papers.concat(coi.pre_audit_work_papers + coi.post_audit_work_papers)
    end

    (self.oportunities + self.final_oportunities).each do |w|
      work_papers.concat(w.work_papers)
    end

    work_papers
  end

  def survey_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait)

    pdf.add_review_header organization, self.identification.strip,
      self.plan_item.project.strip
    pdf.add_title Review.human_attribute_name 'survey'

    pdf.move_pointer PDF_FONT_SIZE

    pdf.text self.survey, :font_size => PDF_FONT_SIZE, :justification => :full

    pdf.move_pointer PDF_FONT_SIZE * 2

    note_text = self.file_model ? I18n.t('review.survey.with_attachment') :
      I18n.t('review.survey.without_attachment')

    pdf.add_footnote "<i>#{note_text}</i>"

    pdf.custom_save_as self.survey_pdf_name, 'review_surveys', self.id
  end

  def absolute_survey_pdf_path
    PDF::Writer.absolute_path self.survey_pdf_name, 'review_surveys', self.id
  end

  def relative_survey_pdf_path
    PDF::Writer.relative_path self.survey_pdf_name, 'review_surveys', self.id
  end

  def survey_pdf_name
    identification = self.identification.gsub /[^A-Za-z0-9\.\-]+/, '_'
    survey = Review.human_attribute_name('survey').downcase.gsub(/\s+/, '_')

    "#{survey}-#{identification}.pdf"
  end

  def score_sheet(organization = nil, draft = false)
    pdf = self.score_sheet_common_header organization, false, draft

    pdf.move_pointer PDF_FONT_SIZE

    columns, column_data = {}, []
    process_controls = {}

    columns['name'] = PDF::SimpleTable::Column.new('name') do |c|
      c.heading = ''
      c.justification = :left
      c.width = pdf.percent_width(70)
    end

    columns['relevance'] = PDF::SimpleTable::Column.new('relevance') do |c|
      c.heading = I18n.t(:'review.control_objectives_relevance')
      c.justification = :center
      c.width = pdf.percent_width(15)
    end

    columns['effectiveness'] = PDF::SimpleTable::Column.new('effectiveness') do |c|
      c.heading = I18n.t(:'review.control_objectives_effectiveness')
      c.justification = :center
      c.width = pdf.percent_width(15)
    end

    self.control_objective_items.each do |coi|
      process_controls[coi.process_control.name] ||= []
      process_controls[coi.process_control.name] << [
        coi.control_objective_text, coi.effectiveness || 0, coi.relevance || 0
      ]
    end

    column_data << {
      'name' => "<b>#{Review.model_name.human}</b> ".to_iso,
      'relevance' => '',
      'effectiveness' => "<b>#{self.effectiveness}%</b>*".to_iso
    }

    process_controls.each do |process_control, coi_data|
      coi_relevance_count = coi_data.inject(0) { |t, e| t + e[2] }.to_f
      effectiveness_average = coi_data.inject(0) do |t, e|
        t + (e[1] * e[2])  / coi_relevance_count
      end

      column_data << {
        'name' => "#{ProcessControl.model_name.human}: #{process_control}".to_iso,
        'relevance' => '',
        'effectiveness' => "#{effectiveness_average.round}%**"
      }

      coi_data.each do |coi|
        column_data << {
          'name' =>
            "        <C:bullet /> <i>#{ControlObjectiveItem.model_name.human}: " +
            "#{coi[0]}</i>".to_iso,
          'relevance' => "<i>#{coi[2]}</i>".to_iso,
          'effectiveness' => "<i>#{coi[1].round}%</i>"
        }
      end
    end

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = ['name', 'relevance', 'effectiveness']
        table.row_gap = PDF_FONT_SIZE
        table.split_rows = true
        table.font_size = PDF_FONT_SIZE
        table.shade_color = Color::RGB::White
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = PDF_FONT_SIZE
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)

    pdf.text "<c:uline><b>#{I18n.t(:'review.notes')}</b></c:uline>:",
      :font_size => (PDF_FONT_SIZE * 0.75).round
    pdf.text "<i>* #{I18n.t(:'review.review_qualification_explanation')}</i>",
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    pdf.text(
      "<i>** #{I18n.t(:'review.process_control_qualification_explanation')}</i>",
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full)

    weaknesses = self.final_weaknesses.all_for_report

    unless weaknesses.blank?
      risk_levels_text = parameter_in(GlobalModelConfig.current_organization_id,
        :admin_finding_risk_levels, self.created_at).
        sort {|r1, r2| r2[1] <=> r1[1]}.map {|r| r[0]}.join(', ')
      pdf.add_subtitle I18n.t(:'review.weaknesses_summary',
        :risks => risk_levels_text), PDF_FONT_SIZE, PDF_FONT_SIZE

      columns, column_data = {}, []
      column_names = {'description' => 60, 'risk' => 15, 'state' => 25}

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = Weakness.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      weaknesses.each do |weakness|
        description = "<b>#{Weakness.human_attribute_name('review_code')}</b>: "
        description << "#{weakness.review_code}\n#{weakness.description}"

        column_data << {
          'description' => description.to_iso,
          'risk' => weakness.risk_text.to_iso,
          'state' => weakness.state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['description', 'risk', 'state']
          table.split_rows = true
          table.row_gap = (PDF_FONT_SIZE * 1.5).round
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    oportunities = self.final_oportunities.all_for_report

    unless oportunities.blank?
      pdf.add_subtitle I18n.t(:'review.oportunities_summary'), PDF_FONT_SIZE,
        PDF_FONT_SIZE

      columns, column_data = {}, []
      column_names = {'description' => 75, 'state' => 25}

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = Oportunity.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      oportunities.each do |oportunity|
        description = "<b>#{Oportunity.human_attribute_name('review_code')}</b>"
        description << ": #{oportunity.review_code}\n#{oportunity.description}"

        column_data << {
          'description' => description.to_iso,
          'state' => oportunity.state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['description', 'state']
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_review_auditors_table(
      self.review_user_assignments.reject { |rua| rua.audited? })

    pdf.custom_save_as(self.score_sheet_name, 'score_sheets', self.id)
  end

  def global_score_sheet(organization = nil, draft = false)
    pdf = self.score_sheet_common_header organization, true, draft

    pdf.move_pointer PDF_FONT_SIZE

    columns, column_data = {}, []
    process_controls = {}

    columns['name'] = PDF::SimpleTable::Column.new('name') do |c|
      c.heading = ''
      c.justification = :left
      c.width = pdf.percent_width(70)
    end

    columns['effectiveness'] = PDF::SimpleTable::Column.new('effectiveness') do |c|
      c.heading = I18n.t(:'review.control_objectives_effectiveness')
      c.justification = :center
      c.width = pdf.percent_width(30)
    end

    self.control_objective_items.each do |coi|
      process_controls[coi.process_control.name] ||= []
      process_controls[coi.process_control.name] << [
        coi.control_objective_text, coi.effectiveness
      ]
    end

    column_data << {
      'name' => "<b>#{Review.model_name.human}</b>".to_iso,
      'effectiveness' => "<b>#{self.effectiveness}%</b>*".to_iso
    }

    process_controls.each do |process_control, coi_data|
      effectiveness_average = coi_data.inject(0) do |t, e|
          (t + e.last  / coi_data.size.to_f)
      end

      column_data << {
        'name' => "#{ProcessControl.model_name.human}: #{process_control}".to_iso,
        'effectiveness' => "#{effectiveness_average.round}%**"
      }
    end

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = ['name', 'effectiveness']
        table.row_gap = PDF_FONT_SIZE
        table.split_rows = true
        table.font_size = PDF_FONT_SIZE
        table.shade_color = Color::RGB::White
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = PDF_FONT_SIZE
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)

    pdf.text "<c:uline><b>#{I18n.t(:'review.notes')}</b></c:uline>:",
      :font_size => (PDF_FONT_SIZE * 0.75).round
    pdf.text "<i>* #{I18n.t(:'review.review_qualification_explanation')}</i>",
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    pdf.text(
      "<i>** #{I18n.t(:'review.process_control_qualification_explanation')}</i>",
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full)

    weaknesses = self.final_weaknesses.all_for_report

    unless weaknesses.blank?
      risk_levels_text = parameter_in(GlobalModelConfig.current_organization_id,
        :admin_finding_risk_levels, self.created_at).
        sort {|r1, r2| r2[1] <=> r1[1]}.map {|r| r[0]}.join(', ')
      pdf.add_subtitle I18n.t(:'review.weaknesses_count_summary',
        :risks => risk_levels_text), PDF_FONT_SIZE, PDF_FONT_SIZE

      columns, column_data = {}, []
      column_names = {
        'count' => I18n.t(:'review.weaknesses_count'),
        'risk' => Weakness.human_attribute_name('risk'),
        'state' => Weakness.human_attribute_name('state')
      }

      column_names.each do |col_name, col_text|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_text
          c.justification = :full
          c.width = pdf.percent_width(100.0 / column_names.size)
        end
      end
      
      weakness = weaknesses.first
      risk_text, state_text = weakness.risk_text, weakness.state_text
      count = 0

      weaknesses.each do |w|
        if risk_text == w.risk_text && state_text == w.state_text
          count += 1
        else
          column_data << {
            'count' => count,
            'risk' => risk_text.to_iso,
            'state' => state_text.to_iso
          }

          risk_text, state_text = w.risk_text, w.state_text
          count = 1
        end
      end

      if count > 0
        column_data << {
          'count' => count,
          'risk' => risk_text.to_iso,
          'state' => state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['count', 'risk', 'state']
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    oportunities = self.final_oportunities.all_for_report

    unless oportunities.blank?
      risk_levels_text = parameter_in(GlobalModelConfig.current_organization_id,
        :admin_finding_risk_levels, self.created_at).
        sort {|r1, r2| r2[1] <=> r1[1]}.map {|r| r[0]}.join(', ')
      pdf.add_subtitle I18n.t(:'review.oportunities_count_summary'),
        PDF_FONT_SIZE, PDF_FONT_SIZE

      columns, column_data = {}, []
      column_names = {
        'count' => Oportunity.human_attribute_name('count'),
        'state' => Oportunity.human_attribute_name('state')
      }

      column_names.each do |col_name, col_text|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_text
          c.justification = :full
          c.width = pdf.percent_width(100.0 / column_names.size)
        end
      end

      oportunity = oportunities.first
      state_text = oportunity.state_text
      count = 0

      oportunities.each do |o|
        if state_text == o.state_text
          count += 1
        else
          column_data << {
            'count' => count,
            'state' => state_text.to_iso
          }

          state_text = o.state_text
          count = 1
        end
      end

      if count > 0
        column_data << {
          'count' => count,
          'state' => state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['count', 'state']
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = PDF_FONT_SIZE
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_review_auditors_table(
      self.review_user_assignments.select { |rua| !rua.audited? })

    pdf.custom_save_as(self.global_score_sheet_name, 'global_score_sheets',
      self.id)
  end

  def score_sheet_common_header(organization = nil, global = false,
      draft = false)
    pdf = PDF::Writer.create_generic_pdf(:portrait)

    pdf.add_review_header organization, self.identification,
      self.plan_item.project
    pdf.add_title(global ? I18n.t(:'review.global_score_sheet_title') :
        I18n.t(:'review.score_sheet_title'))

    pdf.add_watermark(I18n.t(:'pdf.draft')) if draft

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      self.business_unit.business_unit_type.business_unit_label,
      self.business_unit.name)

    unless self.business_unit.business_unit_type.project_label.blank?
      pdf.add_description_item(
        self.business_unit.business_unit_type.project_label,
        self.plan_item.project)
    end

    pdf.add_description_item(
      I18n.t(:'review.audit_period_title'),
      I18n.t(:'review.audit_period',
        :start => I18n.l(self.plan_item.start, :format => :long),
        :end => I18n.l(self.plan_item.end, :format => :long)
      )
    )
    
    users = self.review_user_assignments.reject { |rua| rua.audited? }
    pdf.add_description_item(I18n.t(:'review.auditors'),
      users.map { |rua| rua.user.full_name }.join('; '))

    pdf.add_subtitle I18n.t(:'review.score'), PDF_FONT_SIZE, PDF_FONT_SIZE

    self.add_score_details_table(pdf)

    pdf
  end

  def add_score_details_table(pdf)
    scores = self.get_parameter(:admin_review_scores)
    review_score = self.score.first
    columns = {}
    column_data = {}

    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }

    scores.each_with_index do |score, i|
      min_percentage = score[1]
      max_percentage = i > 0 && scores[i - 1] ? scores[i - 1][1] - 1 : 100
      column_text = "#{score[0]}"

      columns[score[1]] = PDF::SimpleTable::Column.new(score[1]) do |c|
        heading = PDF::SimpleTable::Column::Heading.new(
          score[0] != review_score ? column_text.to_iso :
            "<b>#{column_text.upcase} (#{self.effectiveness}%)</b>".to_iso
        )
        heading.justification = :center
        c.heading = heading
        c.justification = :center
        c.width = pdf.percent_width(100.0 / scores.size)
      end

      column_data[score[1]] = "#{max_percentage}% - #{min_percentage}%"
    end

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = [column_data]
        table.column_order = scores.map { |s| s[1] }
        table.header_gap = (PDF_FONT_SIZE * 1.25).round
        table.row_gap = (PDF_FONT_SIZE * 0.25).round
        table.protect_rows = 2
        table.heading_font_size = (PDF_FONT_SIZE * 1.25).round
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_rows = :none
        table.position = :left
        table.orientation = :right
        table.inner_line_style = PDF::Writer::StrokeStyle.new(0.01)
        table.render_on pdf
      end
    end
  end

  def absolute_score_sheet_path
    PDF::Writer.absolute_path(self.score_sheet_name, 'score_sheets', self.id)
  end

  def relative_score_sheet_path
    PDF::Writer.relative_path(self.score_sheet_name, 'score_sheets', self.id)
  end

  def score_sheet_name
    identification = self.sanitized_identification

    "#{I18n.t(:'review.score_sheet_filename')}-#{identification}.pdf"
  end

  def absolute_global_score_sheet_path
    PDF::Writer.absolute_path(self.global_score_sheet_name,
      'global_score_sheets', self.id)
  end

  def relative_global_score_sheet_path
    PDF::Writer.relative_path(self.global_score_sheet_name,
      'global_score_sheets', self.id)
  end

  def global_score_sheet_name
    identification = self.sanitized_identification

    "#{I18n.t(:'review.global_score_sheet_filename')}-#{identification}.pdf"
  end

  def sanitized_identification
    self.identification.strip.gsub /[^A-Za-z0-9\.\-]+/, '_'
  end

  def zip_all_work_papers(organization = nil)
    filename = self.absolute_work_papers_zip_path
    dirs = {
      :pre_audit => I18n.t(:'review.pre_audit_work_papers').gsub(/\//, '|'),
      :post_audit => I18n.t(:'review.post_audit_work_papers').gsub(/\//, '|'),
      :weaknesses => I18n.t(:'review.weaknesses_work_papers').gsub(/\//, '|'),
      :oportunities => I18n.t(:'review.oportunities_work_papers').gsub(/\//, '|'),
      :follow_up => I18n.t(:'review.follow_up_work_papers').gsub(/\//, '|'),
      :survey => Review.human_attribute_name(:survey).gsub(/\//, '|')
    }

    FileUtils.rm filename if File.exists?(filename)
    FileUtils.makedirs File.dirname(filename)

    Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zipfile|
      dirs.values.each { |d| zipfile.mkdir d }

      self.control_objective_items.each do |coi|
        coi.pre_audit_work_papers.each do |pa_wp|
          self.add_work_paper_to_zip pa_wp, dirs[:pre_audit], zipfile
        end

        coi.post_audit_work_papers.each do |pa_wp|
          self.add_work_paper_to_zip pa_wp, dirs[:post_audit], zipfile
        end
      end
      
      if self.has_final_review?
        weaknesses = self.final_weaknesses
        oportunities = self.final_oportunities
        findings = self.weaknesses + self.oportunities
      else
        weaknesses = self.weaknesses
        oportunities = self.oportunities
        findings = []
      end

      weaknesses.each do |w|
        w.work_papers.each do |w_wp|
          self.add_work_paper_to_zip w_wp, dirs[:weaknesses], zipfile
        end
      end

      oportunities.each do |o|
        o.work_papers.each do |o_wp|
          self.add_work_paper_to_zip o_wp, dirs[:oportunities], zipfile
        end
      end

      findings.each do |f|
        f.work_papers.each do |f_wp|
          self.add_work_paper_to_zip f_wp, dirs[:follow_up], zipfile
        end
      end

      if self.file_model
        self.add_file_to_zip self.file_model.full_filename,
          self.file_model.filename, dirs[:survey], zipfile
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
    filename_prefix = I18n.t(:'review.work_papers').downcase.gsub(
      /[^A-Za-z0-9\.\-]+/, '_')
    path = ('%08d' % (GlobalModelConfig.current_organization_id || 0)).scan(/..../) +
      [Review.table_name] + ('%08d' % self.id).scan(/..../) +
      ["#{filename_prefix}-#{self.sanitized_identification}.zip"]

    File.join *path
  end

  def add_work_paper_to_zip(wp, dir, zipfile)
    if wp.file_model
      self.add_file_to_zip(wp.file_model.full_filename, wp.file_model.filename,
        dir, zipfile)
    else
      identification = self.sanitized_identification
      wp.create_pdf_cover(identification, self)

      self.add_file_to_zip(wp.absolute_cover_path(identification),
        wp.pdf_cover_name(identification), dir, zipfile)
    end
  end

  def add_file_to_zip(file_path, zip_filename, zip_dir, zipfile)
    zip_filename = File.join zip_dir, zip_filename
    
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
    last_code = findings.map do |f|
      f.review_code.match(/\d+\Z/)[0].to_i if f.review_code =~ /\d+\Z/
    end.compact.sort.last

    last_number = last_code.blank? ? 0 : last_code

    "#{prefix}#{'%.2d' % last_number.next}".strip
  end
end