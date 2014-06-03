class LoginRecordPdf < Prawn::Document

  def initialize from, to, login_records, current_organization
    @current_organization = current_organization
    @from, @to, @login_records = from, to, login_records


    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def generate
    add_header
    add_description
    add_body
    create_pdf
  end

  private

    def add_header
      @pdf.add_generic_report_header @current_organization
      @pdf.add_title I18n.t('login_record.index_title')
    end

    def add_description
      @pdf.move_down PDF_FONT_SIZE
      @pdf.add_description_item(I18n.t('login_record.period.title'),
        I18n.t('login_record.period.range',
          from_date: I18n.l(@from, format: :long),
          to_date: I18n.l(@to, format: :long))
        )
    end

    def add_body
      column_order = [['user_id', 20], ['start', 15], ['end', 15], ['data', 50]]
      column_data, column_headers, column_widths = [], [], []

      column_order.each do |col_name, col_with|
        column_headers << LoginRecord.human_attribute_name(col_name)
        column_widths << @pdf.percent_width(col_with)
      end

      @login_records.each do |login_record|
        column_data << [
          "<b>#{login_record.user.user}</b>",
          login_record.start ? I18n.l(login_record.start, format: :minimal) : '-',
          login_record.end ? I18n.l(login_record.end, format: :minimal) : '-',
          login_record.data
        ]
      end

      unless column_data.blank?
        @pdf.move_down PDF_FONT_SIZE
        @pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = @pdf.default_table_options(column_widths)

          @pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end
    end

    def create_pdf
      pdf_name = I18n.t('login_record.pdf_list_name',
        from_date: @from.to_formatted_s(:db),
        to_date: @to.to_formatted_s(:db)
      )

      @pdf.custom_save_as(pdf_name, LoginRecord.table_name)

      Prawn::Document.relative_path(pdf_name, LoginRecord.table_name)
    end
end
