module Reviews::ScoreSheetGlobal
  extend ActiveSupport::Concern

  def global_score_sheet organization = nil, draft: false
    pdf = score_sheet_common_header organization, global: true, draft: draft

    pdf.move_down PDF_FONT_SIZE

    put_process_control_table_on pdf
    put_score_sheet_notes_on     pdf
    put_weaknesses_counts_on     pdf
    put_oportunities_counts_on   pdf

    pdf.move_down PDF_FONT_SIZE * 2

    put_review_signatures_table_on pdf

    pdf.custom_save_as global_score_sheet_name, 'global_score_sheets', id
  end

  def absolute_global_score_sheet_path
    Prawn::Document.absolute_path global_score_sheet_name, 'global_score_sheets', id
  end

  def relative_global_score_sheet_path
    Prawn::Document.relative_path global_score_sheet_name, 'global_score_sheets', id
  end

  def global_score_sheet_name
    identification = sanitized_identification

    "#{I18n.t('review.global_score_sheet_filename')}-#{identification}.pdf"
  end

  private

    def put_process_control_table_on pdf
      row_data = process_controls_row_data

      if row_data.size > 1
        data          = row_data.insert 0, process_control_column_headers
        table_options = pdf.default_table_options process_control_column_widths(pdf)

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

    def put_weaknesses_counts_on pdf
      row_data = weaknesses_count_row_data

      if row_data.present?
        data          = row_data.insert 0, weaknesses_count_column_headers
        table_options = pdf.default_table_options weaknesses_count_column_widths(pdf)

        put_risk_subtitle_on pdf

        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          pdf.table(data, table_options) do
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

    def put_oportunities_counts_on pdf
      row_data = oportunities_count_row_data

      if row_data.present?
        data          = row_data.insert 0, oportunities_count_column_headers
        table_options = pdf.default_table_options oportunities_count_column_widths(pdf)

        pdf.move_down PDF_FONT_SIZE
        pdf.add_subtitle I18n.t('review.oportunities_count_summary'), PDF_FONT_SIZE, PDF_FONT_SIZE

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

    def process_controls_row_data
      row_data         = [initial_process_control_row_data]
      process_controls = collect_process_controls

      process_controls.each do |process_control, coi_data|
        effectiveness = control_objective_effectiveness_for coi_data
        exclude       = coi_data.all? { |e| e[3] }
        row           =
          process_control_row_data(process_control, effectiveness, exclude, global: true)

        row_data << row
      end

      row_data
    end

    def process_control_column_headers
      [
        '',
        I18n.t('review.control_objectives_effectiveness')
      ]
    end

    def process_control_column_widths pdf
      [70, 30].map { |percent| pdf.percent_width percent }
    end

    def weaknesses_count_column_headers
      [
        I18n.t('review.weaknesses_count'),
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('state')
      ]
    end

    def weaknesses_count_column_widths pdf
      weaknesses_count_column_headers.map do |_|
        pdf.percent_width 100.0 / weaknesses_count_column_headers.size
      end
    end

    def initial_process_control_row_data
      [
        "<b>#{Review.model_name.human}</b>",
        "<b>#{self.score}%</b>*"
      ]
    end

    def weaknesses_count_row_data
      row_data   = []
      weaknesses = final_weaknesses.all_for_report

      if weaknesses.any?
        weakness   = weaknesses.first
        risk_text  = weakness.risk_text
        state_text = weakness.state_text
        row_data   = weaknesses_count_row_data_from weaknesses, risk_text, state_text
      end

      row_data
    end

    def weaknesses_count_row_data_from weaknesses, risk_text, state_text
      row_data = []
      count    = 0

      weaknesses.each do |w|
        if risk_text == w.risk_text && state_text == w.state_text
          count += 1
        else
          row_data << [count, risk_text, state_text]

          risk_text, state_text = w.risk_text, w.state_text
          count = 1
        end
      end

      row_data << [count, risk_text, state_text] if count > 0

      row_data
    end

    def oportunities_count_column_headers
      [
        Oportunity.human_attribute_name(:count),
        Oportunity.human_attribute_name(:state)
      ]
    end

    def oportunities_count_column_widths pdf
      oportunities_count_column_headers.map do |_|
        pdf.percent_width 100.0 / oportunities_count_column_headers.size
      end
    end

    def oportunities_count_row_data
      row_data     = []
      oportunities = final_oportunities.all_for_report

      if oportunities.any?
        state_text = oportunities.first.state_text
        row_data   = oportunities_count_row_data_from oportunities, state_text
      end

      row_data
    end

    def oportunities_count_row_data_from oportunities, state_text
      row_data = []
      count    = 0

      oportunities.each do |o|
        if state_text == o.state_text
          count += 1
        else
          row_data << [count, state_text]

          state_text = o.state_text
          count = 1
        end
      end

      row_data << [count, state_text] if count > 0

      row_data
    end
end
