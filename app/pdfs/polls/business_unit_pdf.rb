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

        add_columns_data column_data
        add_results but
      end
    end

    def add_columns_data column_data
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

    def add_results but
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('polls.total_answered')}: #{@report.business_unit_polls[but][:answered]}"
      pdf.text "#{I18n.t('polls.total_unanswered')}: #{@report.business_unit_polls[but][:unanswered]}"
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('polls.score')}: #{@report.business_unit_polls[but][:calification]}%"
      pdf.move_down PDF_FONT_SIZE * 2
    end

    def save
      pdf.custom_save_as pdf_name, BusinessUnit.table_name
    end
end
