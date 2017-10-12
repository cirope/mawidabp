module Reviews::ScoreSheet
  extend ActiveSupport::Concern

  def score_sheet organization = nil, draft: false
    pdf = score_sheet_common_header organization, draft: draft

    pdf.move_down PDF_FONT_SIZE

    put_control_objective_table_on pdf
    put_score_sheet_notes_on       pdf
    put_weaknesses_on              pdf
    put_oportunities_on            pdf

    pdf.move_down PDF_FONT_SIZE * 2

    put_review_signatures_table_on pdf

    pdf.custom_save_as score_sheet_name, 'score_sheets', id
  end

  def absolute_score_sheet_path
    Prawn::Document.absolute_path score_sheet_name, 'score_sheets', id
  end

  def relative_score_sheet_path
    Prawn::Document.relative_path score_sheet_name, 'score_sheets', id
  end

  def score_sheet_name
    "#{I18n.t 'review.score_sheet_filename'}-#{sanitized_identification}.pdf"
  end

  private

    def put_control_objective_table_on pdf
      row_data = control_objectives_row_data

      if row_data.size > 1
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

    def put_weaknesses_on pdf
      row_data = weaknesses_row_data

      if row_data.present?
        data          = row_data.insert 0, weaknesses_column_headers
        table_options = pdf.default_table_options weaknesses_column_widths(pdf)

        put_risk_subtitle_on pdf

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

    def put_oportunities_on pdf
      row_data = oportunities_row_data

      if row_data.present?
        data          = row_data.insert 0, oportunities_column_headers
        table_options = pdf.default_table_options oportunities_column_widths(pdf)

        pdf.add_subtitle I18n.t('review.oportunities_summary'),
          PDF_FONT_SIZE, PDF_FONT_SIZE

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

    def control_objectives_row_data
      row_data         = [initial_control_objective_row_data]
      process_controls = collect_process_controls

      process_controls.each do |process_control, coi_data|
        effectiveness = control_objective_effectiveness_for coi_data
        exclude       = coi_data.all? { |e| e[3] }
        row           =
          process_control_row_data(process_control, effectiveness, exclude)

        row_data << row
        row_data += control_objective_row_data coi_data
      end

      row_data
    end

    def initial_control_objective_row_data
      [
        "<b>#{Review.model_name.human}</b> ",
        '',
        "<b>#{score}%</b>*"
      ]
    end

    def control_objective_row_data control_objective_item_data
      pad = Prawn::Text::NBSP * 4

      control_objective_item_data.map do |coi|
        [
          "#{pad}• <i>#{ControlObjectiveItem.model_name.human}: #{coi[0]}</i>",
          coi[3] ? '-' : "<i>#{coi[2]}</i>",
          coi[3] ? '-' : "<i>#{coi[1].round}%</i>"
        ]
      end
    end

    def control_objective_column_headers
      [
        '',
        I18n.t('review.control_objectives_relevance'),
        I18n.t('review.control_objectives_effectiveness')
      ]
    end

    def control_objective_column_widths pdf
      [70, 15, 15].map { |percent| pdf.percent_width percent }
    end

    def weaknesses_column_names
      [['description', 60], ['risk', 15], ['state', 25]]
    end

    def weaknesses_column_headers
      weaknesses_column_names.map do |col_name, _|
        Weakness.human_attribute_name col_name
      end
    end

    def weaknesses_column_widths pdf
      weaknesses_column_names.map do |_, col_size|
        pdf.percent_width col_size
      end
    end

    def weaknesses_row_data
      final_weaknesses.all_for_report.map do |weakness|
        [
          "<b>#{weakness.review_code}</b>: #{weakness.title}",
          weakness.risk_text,
          weakness.state_text
        ]
      end
    end

    def oportunities_column_names
      [['description', 75], ['state', 25]]
    end

    def oportunities_column_headers
      oportunities_column_names.map do |col_name, _|
        Oportunity.human_attribute_name col_name
      end
    end

    def oportunities_column_widths pdf
      oportunities_column_names.map do |_, col_size|
        pdf.percent_width col_size
      end
    end

    def oportunities_row_data
      final_oportunities.all_for_report.map do |oportunity|
        [
          "<b>#{oportunity.review_code}</b>: #{oportunity.title}",
          oportunity.state_text
        ]
      end
    end
end
