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
      if @report.questionnaire.questions.multi_choice.any?
        pdf.move_down PDF_FONT_SIZE * 1.5
        put_multi_choice_table
      end

      if @report.questionnaire.questions.yes_no.any?
        pdf.move_down PDF_FONT_SIZE * 1.5
        put_yes_no_table
      end

      if @report.questionnaire.questions.written.any?
        pdf.move_down PDF_FONT_SIZE * 1.5
        put_written_table
      end
    end

    def put_multi_choice_table
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(multi_choice_column_data.insert(0, multi_choice_column_headers), multi_choice_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def put_yes_no_table
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(yes_no_column_data.insert(0, yes_no_column_headers), yes_no_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def put_written_table
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(written_column_data.insert(0, written_column_headers), written_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def multi_choice_table_options
      pdf.default_table_options(multi_choice_column_widths)
    end

    def multi_choice_column_data
      column_data = []

      @report.questionnaire.questions.multi_choice.each do |question|
        answers = @report.rates[question.question]

        column_data << multi_choice_answer_options(question.question, answers)
      end

      column_data
    end

    def yes_no_table_options
      pdf.default_table_options(yes_no_column_widths)
    end

    def yes_no_column_data
      column_data = []

      @report.questionnaire.questions.yes_no.each do |question|
        answers = @report.rates[question.question]

        column_data << yes_no_answer_options(question.question, answers)
      end

      column_data
    end

    def written_table_options
      pdf.default_table_options(written_column_widths)
    end

    def written_column_data
      column_data = []

      @report.questionnaire.questions.written.each do |question|
        answers = @report.rates[question.question]

        column_data << written_answer_options(question.question, answers)
      end

      column_data
    end

    def save
      pdf.custom_save_as pdf_name, Questionnaire.table_name
    end
end
