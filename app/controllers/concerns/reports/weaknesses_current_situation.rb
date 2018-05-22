module Reports::WeaknessesCurrentSituation
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_current_situation
    @controller = params[:controller_name]
    @title = t("#{@controller}_committee_report.weaknesses_current_situation_title")
    @from_date, @to_date = *make_date_range(params[:weaknesses_current_situation])
    @filters = []
    final = params[:final] == 'true'
    weaknesses_conditions = {}
    not_muted_states = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
    mute_state_filter_on = Finding::STATUS.except(*not_muted_states).map do |k, v|
      v.to_s
    end
    order = [
      "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
      "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
      "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
    ]
    weaknesses = Weakness.
      finals(final).
      list_with_final_review.
      by_issue_date('BETWEEN', @from_date, @to_date).
      includes(:business_unit, :business_unit_type, review: [:plan_item, :conclusion_final_review]).
      order(order)

    if params[:weaknesses_current_situation]
      risk = Array(params[:weaknesses_current_situation][:risk]).reject(&:blank?)
      states = Array(params[:weaknesses_current_situation][:finding_status]).reject(&:blank?)

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r.to_i]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""
      end

      if states.present?
        weaknesses_conditions[:state] = states

        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s.to_i]}"
          end

          @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
        end
      end

      if params[:weaknesses_current_situation][:finding_title].present?
        weaknesses_conditions[:title] = params[:weaknesses_current_situation][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{weaknesses_conditions[:title]}\""
      end
    end

    weaknesses = weaknesses.by_risk(risk) if risk.present?
    report_weaknesses = weaknesses.with_status_for_report
    report_weaknesses = report_weaknesses.where(state: states) if states.present?
    report_weaknesses = report_weaknesses.with_title(weaknesses_conditions[:title]) if weaknesses_conditions[:title]

    @weaknesses = report_weaknesses
  end

  def create_weaknesses_current_situation
    self.weaknesses_current_situation

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each_with_index do |weakness, index|
        title = [
          "<b>#{index + 1}</b>",
          "<i>#{BusinessUnit.model_name.human}:</i>",
          weakness.business_unit
        ].join(' ')

        pdf.text title, size: PDF_FONT_SIZE, inline_format: true, align: :justify

        current_situation_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_current_situation.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_current_situation')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_current_situation')
  end

  private

    def current_situation_pdf_items weakness
      [
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          BusinessUnitType.model_name.human,
          weakness.business_unit_type
        ],
        [
          I18n.t('follow_up_committee_report.weaknesses_current_situation.origination_year'),
          (l(weakness.origination_date, format: '%Y') if weakness.origination_date)
        ],
        [
          ConclusionFinalReview.human_attribute_name('conclusion'),
          weakness.review.conclusion_final_review.conclusion
        ],
        [
          Weakness.human_attribute_name('risk'),
          weakness.risk_text
        ],
        [
          "<font size='#{PDF_FONT_SIZE + 2}'>#{Weakness.human_attribute_name('title')}</font>",
          "<font size='#{PDF_FONT_SIZE + 2}'><b>#{weakness.title}</b></font>"
        ],
        [
          "<b>#{Weakness.human_attribute_name(weakness.current_situation.present? ? 'current_situation' : 'description')}</b>",
          weakness.current_situation.present? ? weakness.current_situation : weakness.description
        ],
        [
          "<b>#{Weakness.human_attribute_name('answer')}</b>",
          weakness.answer
        ],
        [
          "<b>#{Weakness.human_attribute_name('state')}</b>",
          weakness.state_text
        ],
        ([
          "<b>#{Weakness.human_attribute_name('follow_up_date')}</b>",
          weakness.follow_up_date < Time.zone.today ?
            "<color rgb='ff0000'>#{I18n.l(weakness.follow_up_date)}</color>" :
            I18n.l(weakness.follow_up_date)
        ] if weakness.follow_up_date)
      ].compact
    end
end
