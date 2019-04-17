class Polls::BusinessUnitPdf < Prawn::Document
  include Polls::PDFHeaders
  include Polls::PDFColumns

  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :landscape

    generate
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, BusinessUnit.table_name
  end

  private

    def generate
      pdf_add_header

      if @report.business_unit_polls.present?
        pdf_add_description
        pdf_add_body
      else
        pdf.text I18n.t('polls.without_data')
      end

      save
    end

    def pdf_add_body
      @report.business_unit_polls.each_key do |but|
        pdf.move_down PDF_FONT_SIZE
        pdf.text "<b>#{but}</b>", font_size: PDF_FONT_SIZE * 1.3, inline_format: true

        if @report.questionnaire.questions.multi_choice.any?
          pdf.move_down PDF_FONT_SIZE
          multi_choice_rate_table but
        end

        if @report.questionnaire.questions.yes_no.any?
          pdf.move_down PDF_FONT_SIZE
          yes_no_rate_table but
        end

        if @report.questionnaire.questions.written.any?
          pdf.move_down PDF_FONT_SIZE
          written_rate_table but
        end

        add_results but
      end
    end

    def multi_choice_rate_table but
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(multi_choice_column_data(but).insert(0, multi_choice_column_headers), multi_choice_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def yes_no_rate_table but
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(yes_no_column_data(but).insert(0, yes_no_column_headers), yes_no_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def written_rate_table but
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        pdf.table(written_column_data(but).insert(0, written_column_headers), written_table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def multi_choice_column_data but
      @report.questionnaire.questions.multi_choice.map do |question|
        answers = @report.business_unit_polls[but][:rates][question.question]

        multi_choice_answer_options question.question, answers
      end
    end

    def multi_choice_table_options
      pdf.default_table_options(multi_choice_column_widths)
    end

    def yes_no_column_data but
      @report.questionnaire.questions.yes_no.map do |question|
        answers = @report.business_unit_polls[but][:rates][question.question]

        yes_no_answer_options question.question, answers
      end
    end

    def yes_no_table_options
      pdf.default_table_options(yes_no_column_widths)
    end

    def written_column_data but
      @report.questionnaire.questions.written.map do |question|
        answers = @report.business_unit_polls[but][:rates][question.question]

        written_answer_options question.question, answers
      end
    end

    def written_table_options
      pdf.default_table_options(written_column_widths)
    end

    def add_results but
      pdf.move_down PDF_FONT_SIZE * 1.5
      pdf.text "#{I18n.t('polls.total_answered')}: #{@report.business_unit_polls[but][:answered]}"
      pdf.text "#{I18n.t('polls.total_unanswered')}: #{@report.business_unit_polls[but][:unanswered]}"
      add_score but
    end

    def add_score but
      pdf.move_down PDF_FONT_SIZE * 0.5
      pdf.text "#{I18n.t('polls.score')}: #{@report.business_unit_polls[but][:calification]}%"
    end

    def save
      pdf.custom_save_as pdf_name, BusinessUnit.table_name
    end
end
