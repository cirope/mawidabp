class LoginRecordPdf < Prawn::Document
  attr_reader :pdf

  def initialize from: nil, to: nil, login_records: nil,
    current_organization: nil

    @current_organization = current_organization
    @from, @to, @login_records = from, to, login_records

    @pdf = Prawn::Document.create_generic_pdf :landscape

    generate
  end

  def relative_path
    Prawn::Document.relative_path(pdf_name, LoginRecord.table_name)
  end

  private

    def generate
      add_header
      add_description
      add_body
      save
    end

    def add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title I18n.t('login_records.index.title')
    end

    def add_description
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item(
        I18n.t('login_records.period.title'),
        I18n.t('login_records.period.range',
          from_date: I18n.l(@from, format: :long),
          to_date: I18n.l(@to, format: :long))
      )
    end

    def add_body
      column_data = make_column_data

      if column_data.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = @pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end
    end

    def make_column_data
      @login_records.map do |login_record|
        [
          "<b>#{login_record.user.user}</b>",
          login_record.start ? I18n.l(login_record.start, format: :minimal) : '-',
          login_record.end ? I18n.l(login_record.end, format: :minimal) : '-',
          login_record.data
        ]
      end
    end

    def column_order
      { 'user_id' => 20, 'start' => 15, 'end' => 15, 'data' => 50 }
    end

    def column_headers
      column_order.keys.map { |col_name| LoginRecord.human_attribute_name(col_name) }
    end

    def column_widths
      column_order.values.map { |col_with| pdf.percent_width(col_with) }
    end

    def save
      pdf.custom_save_as(pdf_name, LoginRecord.table_name)
    end

    def pdf_name
      I18n.t 'login_records.pdf_list_name',
        from_date: @from.to_s(:db), to_date: @to.to_s(:db)
    end
end
