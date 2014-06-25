class Polls::QuestionnairePdf < Prawn::Document
  include Polls::PDFHeaders

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
      'questionnaire', 0
    )
  end

  private

    def generate
      pdf_add_header

      if @report.polls.present?
        pdf_add_description
        pdf_add_body
        pdf_add_footer
      else
        pdf.text I18n.t('poll.without_data')
      end

      save
    end

    def pdf_add_body
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def pdf_add_footer
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('poll.total_answered')}: #{@report.answered}"
      pdf.text "#{I18n.t('poll.total_unanswered')}: #{@report.unanswered}"
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('poll.score')}: #{@report.calification}%"
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

    def column_data
      column_data = []

      @report.rates.each do |question, answers|
        new_row = []
        new_row << question

        Question::ANSWER_OPTIONS.each_with_index do |option, i|
          new_row << "#{answers[i]} %"
        end

        column_data << new_row
      end

      column_data
    end

    def save
      pdf.custom_save_as(
        I18n.t('poll.summary_pdf_name',
        from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)
      ), 'questionnaire', 0)
    end
end
