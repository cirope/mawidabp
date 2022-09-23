module Reports::NbcAnnualReport
  include Reports::Pdf

  def nbc_annual_report
    @form = NbcAnnualReportForm.new(new_annual_report)
  end

  def create_nbc_annual_report
    @form = NbcAnnualReportForm.new(new_annual_report)

    if @form.validate(params[:nbc_annual_report])
      @controller  = 'conclusion'
      period       = @form.period
      organization = Current.organization
      pdf          = Prawn::Document.create_generic_pdf :portrait,
                                                        margins: [30, 20, 20, 25]

      put_nbc_cover_on      pdf, organization
      put_executive_summary pdf, organization
      put_detailed_report   pdf, period

      save_pdf(pdf, @controller, period.start, period.end, 'nbc_annual_report')
      redirect_to_pdf(@controller, period.start, period.end, 'nbc_annual_report')
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

    def put_nbc_cover_on pdf, organization
      pdf.add_review_header organization, nil, nil

      pdf.move_down PDF_FONT_SIZE

      width       = pdf.bounds.width
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]
      text_title  = [
        I18n.t('conclusion_review.nbc.cover.title'),
        I18n.t('conclusion_committee_report.nbc_annual_report.front_page.first_title'),
        organization
      ].join "\n"

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.text text_title, size: (PDF_FONT_SIZE * 1.5).round,
                             align: :center,
                             valign: :center,
                             inline_format: true

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      column_data = [
        [I18n.t('conclusion_review.nbc.cover.issue_date'), I18n.l(@form.date, format: :long)],
        [I18n.t('conclusion_review.nbc.cover.to'), I18n.t('conclusion_review.nbc.cover.to_label')],
        [I18n.t('conclusion_review.nbc.cover.from'), I18n.t('conclusion_review.nbc.cover.from_label')],
        [I18n.t('conclusion_review.nbc.cover.cc'), @form.cc ]
      ]

      width_column1 = PDF_FONT_SIZE * 7
      width_column2 = pdf.bounds.width - width_column1

      pdf.table(column_data, cell_style: { inline_format: true }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          borders: [:top, :left, :right]
        )
        row(1).style(
          borders: [:left, :right]
        )
        row(2).style(
          borders: [:bottom, :left, :right]
        )
      end

      pdf.move_down (pdf.y - PDF_FONT_SIZE.pt * 8)
      put_nbc_grid pdf

      pdf.start_new_page
    end

    def put_nbc_grid pdf
      column_data = [
        [
          I18n.t('conclusion_committee_report.nbc_annual_report.front_page.footer_title'),
          @form.name,
          I18n.t('conclusion_committee_report.nbc_annual_report.front_page.footer_prepared_by'),
        ]
      ]

      w_c = pdf.bounds.width / 3

      pdf.table(column_data, cell_style: { size: (PDF_FONT_SIZE * 0.75).round, inline_format: true },
                column_widths: w_c)
    end

    def put_executive_summary pdf, organization
      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.executive_summary.title'),
               align: :center,
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.executive_summary.objective_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text @form.objective, align: :justify

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.executive_summary.general_conclusion_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text @form.conclusion, align: :justify

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.table [[{ content: '', border_width: [0, 0, 1, 0] }]], column_widths: [140]

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.executive_summary.first_footer'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.executive_summary.second_footer'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text "<b>#{organization}</b>", inline_format: true

      pdf.start_new_page
    end

    def put_detailed_report pdf, period
      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.title'),
               align: :center,
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.introduction_and_scope_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text @form.introduction_and_scope

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.classification_methodology'),
               align: :justify

      pdf.move_down PDF_FONT_SIZE

      put_cycle_qualification pdf

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.classification_title',
                      period: period.name),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      put_internal_control_qualification_and_conclusion pdf
    end

    def put_cycle_qualification pdf
      pdf.table [
        [
          {
            content: I18n.t('conclusion_committee_report.nbc_annual_report.cycle_qualification.header_number'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_annual_report.cycle_qualification.header_qualification'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_annual_report.cycle_qualification.header_weight'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_annual_report.cycle_qualification.header_high_risk_observations'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          }
        ],
        [
          { content: '1', size: 8 },
          { content: I18n.t('conclusion_review.nbc.results_by_weighting.adequate'), size: 8 },
          { content: '0-2', align: :center, size: 8 },
          { content: '0', align: :center, size: 8 }
        ],
        [
          { content: '2', size: 8 },
          { content: I18n.t('conclusion_review.nbc.results_by_weighting.require_some_improvements'), size: 8 },
          { content: '3-15', align: :center, size: 8 },
          { content: '5', align: :center, size: 8 }
        ],
        [
          { content: '3', size: 8 },
          { content: I18n.t('conclusion_review.nbc.results_by_weighting.require_improvements'), size: 8 },
          { content: '16-50', align: :center, size: 8 },
          { content: '16', align: :center, size: 8 }
        ],
        [
          { content: '4', size: 8 },
          { content: I18n.t('conclusion_review.nbc.results_by_weighting.require_lots_of_improvements'), size: 8 },
          { content: '51-150', align: :center, size: 8 },
          { content: '50', align: :center, size: 8 }
        ],
        [
          { content: '5', size: 8 },
          { content: I18n.t('conclusion_review.nbc.results_by_weighting.inadequate'), size: 8 },
          { content: '>150', align: :center, size: 8 },
          { content: '>50', align: :center, size: 8 }
        ],
      ], column_widths: [20, 170, 60, 180]
    end

    def put_internal_control_qualification_and_conclusion pdf
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

      results = results_internal_qualification

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

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.conclusions_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_annual_report.detailed_report.conclusions_body',
                      calification: annual_qualification),
               inline_format: true,
               align: :justify
    end

    def results_internal_qualification
      result = []

      ######## grouped by business_unit
      BusinessUnit.left_joins(:business_unit_type)
                  .list
                  .where(business_unit_types: { grouped_by_business_unit_annual_report: true })
                  .each do |bu|
                    reviews = ConclusionFinalReview.left_joins(review: :plan_item)
                                                   .where(reviews: {
                                                            plan_items: { business_units: bu },
                                                            type_review: 1,
                                                            period: @form.period
                                                          })
                                                   .map(&:review)

                    add_unit_qualification result, bu, reviews
                  end

      ######## grouped by business_unit_type
      BusinessUnitType.list
                      .where(grouped_by_business_unit_annual_report: false)
                      .each do |but|
                        reviews = ConclusionFinalReview.left_joins(review: :plan_item)
                                                       .where(reviews: {
                                                                plan_items: { business_units: but.business_units },
                                                                type_review: 1,
                                                                period: @form.period
                                                              })
                                                       .map(&:review)

                        add_unit_qualification result, but, reviews
                      end

      result
    end

    def add_unit_qualification array, unit, reviews
      weakness = []

      reviews.each do |review|
        weakness << Weakness.left_joins(control_objective_item: :review)
                            .where(
                              control_objective_items:
                              {
                                reviews: [review] + review.external_reviews.map(&:alternative_review) 
                              },
                              state: Finding::STATUS[:being_implemented],
                              final: true
                            )
      end

      weakness = weakness.flatten

      if weakness.present?
        array << {
          name: unit.name,
          count: weakness.count,
          total_weight: (weakness.sum { |w| w.risk_weight * w.state_weight * w.age_weight } / reviews.count.to_f).round
        }
      end
    end

    def calculate_qualification total_weight
      high_score      = 150
      medium_score    = 50
      hundred_percent = 100

      if total_weight <= medium_score
        score = hundred_percent - total_weight
      elsif total_weight <= high_score
        min = ((hundred_percent - medium_score.next) / 3).to_i
        max = hundred_percent - medium_score.next

        score = max - ((total_weight * min) / high_score)
      else
        min = 1
        max = 16

        score = max - ((total_weight * min) / high_score.next).to_i
      end

      key = Review.scores_by_weaknesses.detect { |_k, v| score >= v }.first

      I18n.t("conclusion_review.nbc.results_by_weighting.#{key}")
    end
end
