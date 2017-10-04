class Review < ApplicationRecord
  include Auditable
  include Parameters::Risk
  include Parameters::Score
  include ParameterSelector
  include Reviews::Approval
  include Reviews::Clone
  include Reviews::ConclusionReview
  include Reviews::ControlObjectiveItems
  include Reviews::DestroyValidation
  include Reviews::Effectiveness
  include Reviews::FileModel
  include Reviews::FindingAssignments
  include Reviews::FindingCode
  include Reviews::Findings
  include Reviews::Scopes
  include Reviews::Score
  include Reviews::Search
  include Reviews::UpdateCallbacks
  include Reviews::Users
  include Reviews::Validations
  include Reviews::WorkPapers
  include Reviews::WorkPapersZip
  include Taggable
  include Trimmer

  trimmed_fields :identification

  belongs_to :period
  belongs_to :plan_item
  belongs_to :organization
  has_one :business_unit, :through => :plan_item
  has_one :workflow, :dependent => :destroy
  has_many :business_unit_scores, :through => :control_objective_items

  def to_s
    "#{long_identification } (#{I18n.l issue_date, format: :minimal})"
  end

  def long_identification
    "#{identification} - #{plan_item.project}"
  end

  def external_audit?
    business_unit.business_unit_type.external
  end

  def internal_audit?
    !external_audit?
  end

  def issue_date(include_draft = false)
    self.conclusion_final_review.try(:issue_date) ||
      (self.conclusion_draft_review.try(:issue_date) if include_draft) ||
      self.plan_item.start
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

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_review_signatures_table(review_user_assignments.select(&:include_signature))

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

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_review_signatures_table(review_user_assignments.select(&:include_signature))

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
end
