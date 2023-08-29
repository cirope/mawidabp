module Reports::NbcAnnualReport
  include Reports::Pdf

  def nbc_annual_report
    @form = NbcAnnualReportForm.new new_annual_report
  end

  def create_nbc_annual_report
    @form = NbcAnnualReportForm.new new_annual_report

    if @form.validate(params[:nbc_annual_report])
      @controller  = 'conclusion'
      period       = @form.period
      organization = Current.organization
      pdf          = Prawn::Document.create_generic_pdf :portrait,
        margins: [30, 20, 20, 25]

      text_titles  = [
        I18n.t('conclusion_committee_report.nbc_annual_report.front_page.first_title'),
        organization
      ]

      put_nbc_cover_on               pdf, organization, text_titles, @form
      put_nbc_executive_summary      pdf, organization, @form
      put_nbc_introduction_and_scope pdf, @form
      put_detailed_report_with_final_weaknesses pdf, period
      put_detailed_report_with_not_final_weaknesses pdf, period

      save_pdf pdf, @controller, period.start, period.end, 'nbc_annual_report'
      redirect_to_pdf @controller, period.start, period.end, 'nbc_annual_report'
    else
      render action: :nbc_annual_report
    end
  end

  private

  def new_annual_report
    OpenStruct.new(
      period_id: '',
      date: Date.today,
      cc: '',
      name: '',
      objective: '',
      conclusion: '',
      introduction_and_scope: ''
    )
  end

  def put_detailed_report_with_final_weaknesses pdf, period
    pdf.move_down PDF_FONT_SIZE * 3

    pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.classification_with_final_weaknesses_title',
                    period: period.name),
                    inline_format: true

    put_nbc_internal_control_qualification_and_conclusion_annual_report pdf, period, true, true

    pdf.start_new_page
  end

  def put_detailed_report_with_not_final_weaknesses pdf, period
    pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.classification_with_not_final_weaknesses_title',
                    period: period.name),
                    inline_format: true

    put_nbc_internal_control_qualification_and_conclusion_annual_report pdf, period, false, false
  end

  def put_nbc_internal_control_qualification_and_conclusion_annual_report pdf, period, final_weaknesses, with_conclusion
    total_cycles = 0
    total_weight = 0
    table        = []

    table << [
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_cycle'),
        align: :center,
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 1, 2, 1]
      },
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_count_findings'),
        align: :center,
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 1, 2, 1]
      },
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_weight'),
        align: :center,
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 1, 2, 1]
      },
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.header_qualification'),
        align: :center,
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 1, 2, 1]
      }
    ]

    results = results_internal_qualification_annual_report period, final_weaknesses

    results.each do |item|
      total_cycles += 1
      total_weight += item[:total_weight]

      table << [
        { content: item[:name], size: 8 },
        { content: item[:count].to_s, align: :center, size: 8 },
        { content: item[:total_weight].to_s, align: :center, size: 8 },
        { content: calculate_qualification(item[:total_weight]), size: 8 }
      ]
    end

    table << [
      { content: '', border_width: [2, 0, 2, 1] },
      { content: '', border_width: [2, 0, 2, 0] },
      { content: '', border_width: [2, 0, 2, 0] },
      { content: '', border_width: [2, 1, 2, 0] }
    ]

    table << [
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_weight'),
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [2, 0, 1, 1]
      },
      { content: '', background_color: '8DB4E2', border_width: [2, 0, 1, 0] },
      { content: '', background_color: '8DB4E2', border_width: [2, 1, 1, 0] },
      {
        content: "<b>#{total_weight}</b>",
        size: 8,
        inline_format: true,
        align: :center,
        border_width: [2, 1, 1, 1]
      }
    ]

    table << [
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.count_cycles'),
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 0, 1, 1]
      },
      { content: '', background_color: '8DB4E2', border_width: [1, 0, 1, 0] },
      { content: '', background_color: '8DB4E2', border_width: [1, 1, 1, 0] },
      {
        content: "<b>#{total_cycles}</b>",
        size: 8,
        inline_format: true,
        align: :center,
        border_width: [1, 1, 1, 1]
      }
    ]

    annual_weight        = (total_weight / (total_cycles.zero? ? 1 : total_cycles.to_f)).round
    annual_qualification = calculate_qualification annual_weight

    table << [
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_weight'),
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [1, 0, 2, 1]
      },
      { content: '', background_color: '8DB4E2', border_width: [1, 0, 2, 0] },
      { content: '', background_color: '8DB4E2', border_width: [1, 1, 2, 0] },
      {
        content: "<b>#{annual_weight}</b>",
        size: 8,
        inline_format: true,
        align: :center,
        border_width: [1, 1, 2, 1]
      }
    ]

    table << [
      {
        content: I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.final_qualification'),
        size: 8,
        inline_format: true,
        background_color: '8DB4E2',
        border_width: [2, 0, 2, 1]
      },
      { content: '', background_color: '8DB4E2', border_width: [2, 0, 2, 0] },
      { content: '', background_color: '8DB4E2', border_width: [2, 1, 2, 0] },
      {
        content: "<b>#{annual_qualification}</b>",
        size: 8,
        inline_format: true,
        align: :center,
        border_width: [2, 1, 2, 1]
      }
    ]

    pdf.table table, column_widths: [110, 110, 110, 110]

    if with_conclusion
      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.conclusions_title'),
        inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.internal_control_qualification.conclusions_body',
                      calification: annual_qualification),
                      inline_format: true,
                      align: :justify
    end
  end

  def results_internal_qualification_annual_report period, final_weaknesses
    result = []

    ######## grouped by business_unit
    BusinessUnit.left_joins(:business_unit_type)
      .list
      .where(business_unit_types: { grouped_by_business_unit_annual_report: true })
      .each do |bu|
        reviews = ConclusionFinalReview.left_joins(review: :plan_item)
          .where(reviews: {
            plan_items: { business_units: bu },
            type_review: Review::TYPES_REVIEW[:operational_audit],
            period: period
          })
            .map(&:review)

          add_unit_qualification_annual_report result, bu, reviews, final_weaknesses
      end

    ######## grouped by business_unit_type
    BusinessUnitType.list
      .where(grouped_by_business_unit_annual_report: false)
      .each do |but|
        reviews = ConclusionFinalReview.left_joins(review: :plan_item)
          .where(reviews: {
            plan_items: { business_units: but.business_units },
            type_review: Review::TYPES_REVIEW[:operational_audit],
            period: period
          })
            .map(&:review)

          add_unit_qualification_annual_report result, but, reviews, final_weaknesses
      end

    result
  end

  def add_unit_qualification_annual_report array, unit, reviews, final_weaknesses
    weaknesses = []

    reviews.each do |review|
      weaknesses << Weakness.left_joins(control_objective_item: :review)
        .where(
          control_objective_items:
          {
            reviews: [review] + review.external_reviews.map(&:alternative_review)
          },
          state: Finding::STATUS[:being_implemented],
          final: final_weaknesses
        )
    end

    weaknesses = weaknesses.flatten

    if weaknesses.present?
      array << {
        name: unit.name,
        count: weaknesses.count,
        total_weight: calculate_total_weight(weaknesses, reviews.count)
      }
    end
  end
end
