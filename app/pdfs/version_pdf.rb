class VersionPdf < Prawn::Document
  def initialize from: nil, to: nil, versions: nil, current_organization: nil
    @current_organization = current_organization
    @from, @to, @versions = from, to, versions

    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def generate
    add_header
    add_body
    save
  end

  def relative_path
    Prawn::Document.relative_path(pdf_name, PaperTrail::Version.table_name)
  end

  private

    def add_header
      @pdf.add_generic_report_header @current_organization
      @pdf.add_title I18n.t('versions.security_changes_report.title')
    end

    def add_body
      column_data = make_column_data

      if column_data.present?
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

    def make_column_data
      @versions.map do |version|
        [
          I18n.l(version.created_at, format: :minimal),
          version.whodunnit ?
            User.find(version.whodunnit).full_name_with_user : '-',
          version.item ?
            "#{version.item.class.model_name.human} (#{version.item})" : '-',
          I18n.t("versions.events.#{version.event}")
        ]
      end
    end

    def column_order
      { 'created_at' => 12, 'whodunnit' => 28, 'item' => 50, 'event' => 10 }
    end

    def column_headers
      column_order.keys.map { |col_name| PaperTrail::Version.human_attribute_name(col_name) }
    end

    def column_widths
      column_order.values.map { |col_with| @pdf.percent_width(col_with) }
    end

    def save
      @pdf.custom_save_as(pdf_name, PaperTrail::Version.table_name)
    end

    def pdf_name
      I18n.t('versions.pdf_list_name',
        from_date: @from.to_s(:db), to_date: @to.to_s(:db))
    end
end
