class Polls::BusinessUnitPdf < Prawn::Document
  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :landscape

    generate
  end

  def relative_path
    Prawn::Document.relative_path(
      I18n.t('poll.summary_pdf_name',
      from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)),
      'business_unit', 0
    )
  end

  private

    def generate
      pdf_add_header

      if @report.business_unit_polls.present?
        pdf_add_description
        pdf_add_body
      else
        pdf.text I18n.t('poll.without_data')
      end

      save
    end

    def columns_order
      columns = { Question.model_name.human => 40 }

      Question::ANSWER_OPTIONS.each do |option|
        columns[I18n.t("activerecord.attributes.answer_option.options.#{option}")] = 12
      end

      columns
    end

    def column_headers
      columns_order.keys
    end

    def column_widths
      columns_order.values.map { |col_with| pdf.percent_width(col_with) }
    end

    def pdf_add_body
      @report.business_unit_polls.each_key do |but|
        pdf.text "<b>#{but}</b>", font_size: PDF_FONT_SIZE * 1.3, inline_format: true
        pdf.move_down PDF_FONT_SIZE * 2
        column_data = []

        @report.business_unit_polls[but][:rates].each do |question, answers|
          new_row = []
          new_row << question

          Question::ANSWER_OPTIONS.each_with_index do |option, i|
            new_row << "#{answers[i]} %"
          end

          column_data << new_row
        end

        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end

        pdf.move_down PDF_FONT_SIZE
        pdf.text "#{I18n.t('poll.total_answered')}: #{@report.business_unit_polls[but][:answered]}"
        pdf.text "#{I18n.t('poll.total_unanswered')}: #{@report.business_unit_polls[but][:unanswered]}"
        pdf.move_down PDF_FONT_SIZE
        pdf.text "#{I18n.t('poll.score')}: #{@report.business_unit_polls[but][:calification]}%"
        pdf.move_down PDF_FONT_SIZE * 2
      end
    end

    def save
      pdf.custom_save_as(
        I18n.t('poll.summary_pdf_name',
        from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)
      ), 'business_unit', 0)
    end

    def pdf_add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title @report.params[:report_title], PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title @report.params[:report_subtitle], PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_description_item(
        I18n.t('activerecord.attributes.poll.send_date'),
        I18n.t('conclusion_committee_report.period.range',
          from_date: I18n.l(@report.from_date, format: :long),
          to_date: I18n.l(@report.to_date, format: :long)
        )
      )
      pdf.move_down PDF_FONT_SIZE
    end

    def pdf_add_description
      pdf.add_description_item(Questionnaire.model_name.human, @report.questionnaire.name)
      pdf.move_down PDF_FONT_SIZE * 2
    end

    def pdf
      @pdf
    end
end
