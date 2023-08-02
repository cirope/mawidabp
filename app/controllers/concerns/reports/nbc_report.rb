module Reports::NbcReport
  include Reports::Pdf

  private

    def put_nbc_cover_on pdf, organization, title_texts, form
      pdf.add_review_header organization, nil, nil

      pdf.move_down PDF_FONT_SIZE

      width       = pdf.bounds.width
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]

      text_title  = [
        I18n.t('conclusion_review.nbc.cover.title'),
        title_texts
      ].flatten.join "\n"

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.text text_title, size: (PDF_FONT_SIZE * 1.5).round,
                             align: :center,
                             valign: :center,
                             inline_format: true

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      column_data = [
        [I18n.t('conclusion_review.nbc.cover.issue_date'), I18n.l(form.date, format: :long)],
        [I18n.t('conclusion_review.nbc.cover.to'), I18n.t('conclusion_review.nbc.cover.to_label')],
        [I18n.t('conclusion_review.nbc.cover.from'), I18n.t('conclusion_review.nbc.cover.from_label')],
        [I18n.t('conclusion_review.nbc.cover.cc'), form.cc ]
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
      put_nbc_grid pdf, form

      pdf.start_new_page
    end

    def put_nbc_grid pdf, form
      column_data = [
        [
          I18n.t('conclusion_committee_report.nbc_report.front_page.footer_title'),
          form.name,
          I18n.t('conclusion_committee_report.nbc_report.front_page.footer_prepared_by'),
        ]
      ]

      w_c = pdf.bounds.width / 3

      pdf.table(column_data, cell_style: { size: (PDF_FONT_SIZE * 0.75).round, inline_format: true },
                column_widths: w_c)
    end

    def put_nbc_executive_summary pdf, organization, form
      pdf.text I18n.t('conclusion_committee_report.nbc_report.executive_summary.title'),
               align: :center,
               inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_committee_report.nbc_report.executive_summary.objective_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text form.objective, align: :justify

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_committee_report.nbc_report.executive_summary.general_conclusion_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text form.conclusion, align: :justify

      pdf.move_down PDF_FONT_SIZE * 3

      pdf.table [[{ content: '', border_width: [0, 0, 1, 0] }]], column_widths: [140]

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_report.executive_summary.first_footer'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_report.executive_summary.second_footer'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text "<b>#{organization}</b>", inline_format: true

      pdf.start_new_page
    end

    def put_nbc_introduction_and_scope pdf, form
      pdf.text I18n.t('conclusion_committee_report.nbc_report.introduction_and_scope.title'),
               align: :center,
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_report.introduction_and_scope.introduction_and_scope_title'),
               inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text form.introduction_and_scope

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_committee_report.nbc_report.introduction_and_scope.classification_methodology'),
               align: :justify

      pdf.move_down PDF_FONT_SIZE

      put_nbc_cycle_qualification pdf
    end

    def put_nbc_cycle_qualification pdf
      pdf.table [
        [
          {
            content: I18n.t('conclusion_committee_report.nbc_report.cycle_qualification.header_number'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_report.cycle_qualification.header_qualification'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_report.cycle_qualification.header_weight'),
            align: :center,
            size: 8,
            inline_format: true,
            background_color: '8DB4E2'
          },
          {
            content: I18n.t('conclusion_committee_report.nbc_report.cycle_qualification.header_high_risk_observations'),
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

    def calculate_total_weight weaknesses, count_reviews
      (weaknesses.sum { |w| w.risk_weight * w.state_weight * w.age_weight } / count_reviews).round
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
