module ConclusionReviews::AlternativePDF
  extend ActiveSupport::Concern

  def alternative_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :portrait, false

    put_watermark_on          pdf
    put_alternative_header_on pdf, organization
    put_alternative_cover_on  pdf
    put_executive_summary_on  pdf
    put_detailed_review_on    pdf
    put_annex_on              pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_alternative_header_on pdf, organization
      pdf.add_review_header organization, nil, nil
      pdf.add_page_footer
    end

    def put_alternative_cover_on pdf
      items_font_size = PDF_FONT_SIZE * 1.5
      business_unit_label =
        review.business_unit.business_unit_type.business_unit_label
      business_unit_title =
        "#{business_unit_label}: #{review.business_unit.name}"
      issue_date_title    =
        I18n.t('conclusion_review.issue_date_title').downcase.camelize

      pdf.move_down PDF_FONT_SIZE * 8
      pdf.text "#{business_unit_title}\n", size: (PDF_FONT_SIZE * 2.5).round,
        align: :center
      pdf.move_down PDF_FONT_SIZE * 4

      if review.business_unit.business_unit_type.project_label.present?
        project_label = review.business_unit.business_unit_type.project_label

        pdf.add_description_item project_label, review.plan_item.project,
          0, false, items_font_size
        pdf.move_down PDF_FONT_SIZE * 2
      end

      pdf.add_description_item Review.model_name.human, review.identification,
        0, false, items_font_size
      pdf.add_description_item issue_date_title, I18n.l(issue_date),
        0, false, items_font_size

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_review.executive_summary.review_author'),
        size: items_font_size
    end

    def put_executive_summary_on pdf
      title = I18n.t 'conclusion_review.executive_summary.title'
      project_title = I18n.t 'conclusion_review.executive_summary.project'
      project = review.plan_item.project

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text "#{project_title} <b>#{project}</b>", inline_format: true

      put_risk_exposure_on           pdf
      put_alternative_score_table_on pdf

      put_main_weaknesses_on         pdf
      put_other_weaknesses_on        pdf
    end

    def put_detailed_review_on pdf
      title  = I18n.t 'conclusion_review.detailed_review.title'
      legend = I18n.t 'conclusion_review.detailed_review.legend'

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text legend, align: :justify, style: :italic

      put_review_survey_on       pdf
      put_detailed_weaknesses_on pdf
      put_recipients_on          pdf
    end

    def put_annex_on pdf
      title  = I18n.t 'conclusion_review.annex.title'
      legend = I18n.t 'conclusion_review.annex.legend'

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text legend, align: :justify

      put_conclusion_options_on pdf
      put_review_scope_on       pdf
      put_staff_on              pdf
      put_sectors_on            pdf
    end

    def put_conclusion_options_on pdf
      text = CONCLUSION_OPTIONS.map(&:upcase).join ' - '

      pdf.move_down PDF_FONT_SIZE
      pdf.text text, align: :center, style: :bold
    end

    def put_review_scope_on pdf
      title = I18n.t 'conclusion_review.annex.scope'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      put_control_objective_items_table_on pdf
    end

    def put_staff_on pdf
      title = I18n.t 'conclusion_review.annex.staff'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      review.review_user_assignments.each do |rua|
        text = "• #{rua.type_text}: #{rua.user.informal_name}"

        pdf.indent(PDF_FONT_SIZE) { pdf.text text }
      end
    end

    def put_sectors_on pdf
      title = self.class.human_attribute_name 'sectors'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      pdf.text sectors, align: :justify
    end

    def put_control_objective_items_table_on pdf
      row_data = control_objectives_row_data

      if row_data.present?
        data          = row_data.insert 0, control_objective_column_headers
        table_options = pdf.default_table_options control_objective_column_widths(pdf)

        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          pdf.table data, table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end
    end

    def put_review_survey_on pdf
      title = Review.human_attribute_name 'survey'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      pdf.text review.survey, align: :justify
    end

    def put_detailed_weaknesses_on pdf
      title = Weakness.model_name.human count: 0

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      put_weakness_details_on pdf, all_weaknesses, legend: 'no_weaknesses'
    end

    def put_recipients_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.text recipients, align: :justify
    end

    def put_risk_exposure_on pdf
      risk_exposure_title = I18n.t 'conclusion_review.executive_summary.risk_exposure'
      risk_exposure       = '<b><color rgb="cc0000">%s</color></b>' % [
        Review.human_attribute_name('risk_exposure'),
        review.risk_exposure
      ].join(': ')

      pdf.move_down PDF_FONT_SIZE

      pdf.table [["#{risk_exposure_title}: #{risk_exposure}"]], {
        width:      pdf.percent_width(100),
        cell_style: {
          align:         :justify,
          inline_format: true,
          border_width:  1,
          padding:       [5, 10, 5, 10]
        }
      }
    end

    def put_alternative_score_table_on pdf
      score_title = I18n.t 'conclusion_review.executive_summary.score'
      score_text  = [
        "<b>#{conclusion.upcase}</b>",
        "<b><color rgb=\"cc0000\">(#{review.score_text})</color></b>"
      ].join("\n")

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title score_title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      pdf.bounding_box [0, pdf.cursor], width: pdf.percent_width(100) do
        inner_width = pdf.percent_width(100) - PDF_FONT_SIZE * 1.5

        pdf.move_down PDF_FONT_SIZE

        pdf.bounding_box [PDF_FONT_SIZE, pdf.cursor], width: inner_width do
          pdf.text score_text, inline_format: true
        end

        put_alternative_score_circle_on pdf
      end
    end

    def put_alternative_score_circle_on pdf
      fill_color = pdf.fill_color
      point      = [
        pdf.bounds.width - 20,
        pdf.bounds.height - PDF_FONT_SIZE
      ]

      pdf.move_down PDF_FONT_SIZE
      pdf.fill_color CONCLUSION_COLORS.fetch(conclusion) { '808080' }
      pdf.fill_ellipse point, PDF_FONT_SIZE
      pdf.fill_color fill_color
      pdf.stroke_bounds
    end

    def put_main_weaknesses_on pdf
      title      = I18n.t 'conclusion_review.executive_summary.main_weaknesses'
      weaknesses = main_weaknesses

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round

      put_weakness_details_on pdf, weaknesses, legend: 'no_main_weaknesses'
    end

    def put_weakness_details_on pdf, weaknesses, legend:
      if weaknesses.any?
        weaknesses.each do |f|
          coi = f.control_objective_item

          pdf.move_down PDF_FONT_SIZE
          pdf.text coi.finding_pdf_data(f), align: :justify, inline_format: true
        end
      else
        put_weakness_legend_on pdf, legend
      end
    end

    def put_other_weaknesses_on pdf
      title      = I18n.t 'conclusion_review.executive_summary.other_weaknesses'
      weaknesses = other_weaknesses

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round

      if weaknesses.any? || assumed_risk_weaknesses.any?
        put_medium_risk_weaknesses_on  pdf
        put_low_risk_weaknesses_on     pdf
        put_assumed_risk_weaknesses_on pdf
      else
        put_weakness_legend_on pdf, 'no_other_weaknesses'
      end
    end

    def put_weakness_legend_on pdf, title
      legend = I18n.t "conclusion_review.executive_summary.#{title}"

      pdf.move_down PDF_FONT_SIZE
      pdf.text legend, align: :justify
      pdf.move_down PDF_FONT_SIZE
    end

    def put_medium_risk_weaknesses_on pdf
      weaknesses = other_weaknesses.where risk: RISK_TYPES[:medium]

      if weaknesses.any?
        title =
          I18n.t 'conclusion_review.executive_summary.medium_risk_weaknesses'

        pdf.move_down PDF_FONT_SIZE
        pdf.add_title title, (PDF_FONT_SIZE * 1.3).round
        pdf.move_down PDF_FONT_SIZE

        weaknesses.each do |w|
          put_short_weakness_on pdf, w
        end
      end
    end

    def put_low_risk_weaknesses_on pdf
      if low_risk_weaknesses.any? || not_relevant_weaknesses.any?
        title =
          I18n.t 'conclusion_review.executive_summary.low_risk_weaknesses_title'
        text = I18n.t "conclusion_review.executive_summary.low_risk_weaknesses",
          count:              low_risk_weaknesses.size,
          not_relevant_count: not_relevant_weaknesses.size

        pdf.move_down PDF_FONT_SIZE
        pdf.add_title title, (PDF_FONT_SIZE * 1.3).round
        pdf.move_down PDF_FONT_SIZE

        pdf.indent PDF_FONT_SIZE do
          pdf.text text, align: :justify
        end
      end
    end

    def put_assumed_risk_weaknesses_on pdf
      weaknesses = assumed_risk_weaknesses

      if weaknesses.any?
        title =
          I18n.t 'conclusion_review.executive_summary.assumed_risk_weaknesses'

        pdf.move_down PDF_FONT_SIZE
        pdf.add_title title, (PDF_FONT_SIZE * 1.3).round
        pdf.move_down PDF_FONT_SIZE

        weaknesses.each do |w|
          put_short_weakness_on pdf, w
        end
      end
    end

    def put_short_weakness_on pdf, weakness
      origination_date = if weakness.origination_date.present?
                           I18n.l weakness.origination_date
                         else
                           '-'
                         end
      state_text = [
        Weakness.human_attribute_name('state'), weakness.state_text
      ].join(': ')
      origination_date_text = [
        Weakness.human_attribute_name('origination_date'), origination_date
      ].join(': ')
      text = [
        weakness.review_code,
        weakness.title,
        state_text,
        origination_date_text
      ].join(' - ')

      pdf.indent PDF_FONT_SIZE do
        pdf.text "• #{text}", align: :justify
      end
    end

    def main_weaknesses
      weaknesses.not_revoked.not_assumed_risk.with_high_risk.sort_for_review
    end

    def other_weaknesses
      weaknesses.not_revoked.not_assumed_risk.with_other_risk.sort_for_review
    end

    def low_risk_weaknesses
      weaknesses.not_revoked.not_assumed_risk.where risk: RISK_TYPES[:low]
    end

    def not_relevant_weaknesses
      weaknesses.not_revoked.not_assumed_risk.where risk: RISK_TYPES[:not_relevant]
    end

    def assumed_risk_weaknesses
      weaknesses.assumed_risk
    end

    def all_weaknesses
      weaknesses.not_revoked.sort_for_review
    end

    def weaknesses
      if kind_of? ConclusionFinalReview
        review.final_weaknesses
      else
        review.weaknesses
      end
    end

    def control_objectives_row_data
      row_data = []

      review.control_objective_items.each do |coi|
        color      = CONCLUSION_COLORS.fetch(coi.auditor_comment) { '808080' }
        icon       = "<font size=\"14\"><color rgb=\"#{color}\">•</color></font>"
        conclusion = "#{icon} #{coi.auditor_comment&.upcase}"

        row_data << [
          coi.control_objective_text,
          conclusion
        ]
      end

      row_data
    end

    def control_objective_column_headers
      [
        "<b>#{I18n.t 'conclusion_review.annex.scope_column'}</b> ",
        "<b>#{self.class.human_attribute_name 'conclusion'}</b>"
      ]
    end

    def control_objective_column_widths pdf
      [70, 30].map { |percent| pdf.percent_width percent }
    end
end
