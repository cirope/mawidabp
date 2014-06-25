class Polls::QuestionnairePdf < Prawn::Document
  include Polls::PDFHeaders
  include Polls::PDFScores
  include Polls::PDFColumns

  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :landscape

    generate
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, Questionnaire.table_name
  end

  private

    def generate
      pdf_add_header

      if @report.polls.present?
        pdf_add_description
        pdf_add_body
        pdf_add_scores
      else
        pdf.text I18n.t('polls.without_data')
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
      pdf.custom_save_as pdf_name, Questionnaire.table_name
    end
end
