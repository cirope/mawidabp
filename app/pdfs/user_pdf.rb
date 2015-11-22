class UserPdf < Prawn::Document
  attr_reader :pdf

  def initialize columns: nil, query: nil, users: nil, current_organization: nil
    @current_organization = current_organization
    @columns, @query, @users = columns, query, users

    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, User.table_name
  end

  def self.create attributes = nil
    _pdf = new attributes

    _pdf.send :generate

    _pdf
  end

  private

    def generate
      add_header
      add_filter_text
      add_body
      save
    end

    def add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title I18n.t('users.index.title')
    end

    def add_filter_text
      if @columns.present? || @query.present?
        filter_columns = @columns.map { |c| "<b>#{User.human_attribute_name c}</b>" }
        query = @query.flatten.map { |q| "<b>#{q}</b>" }
        text = I18n.t 'user.pdf.filtered_by', query: query.to_sentence,
          columns: filter_columns.to_sentence, count: @columns.size

        pdf.move_down PDF_FONT_SIZE
        pdf.text text, font_size: (PDF_FONT_SIZE * 0.75).round, inline_format: true
      end

      pdf.move_down PDF_FONT_SIZE
    end

    def add_body
      column_data = make_column_data

      if column_data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options column_widths

          pdf.table column_data.insert(0, column_headers), table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('user.pdf.users_count', count: @users.size)
    end

    def make_column_data
      @users.map do |user|
        [
          "<b>#{user.user}</b>",
          user.name,
          user.last_name,
          user.email,
          user.function,
          user.roles.map(&:name).join('; '),
          I18n.t(user.enable? ? 'label.yes' : 'label.no'),
          user.password_changed ? I18n.l(user.password_changed, format: :minimal) : '-',
          user.last_access ? I18n.l(user.last_access, format: :minimal) : '-'
        ]
      end
    end

    def column_order
      [
        ['user', 10], ['name', 10], ['last_name', 10], ['email', 17],
        ['function', 14], ['roles', 10], ['enable', 8],
        ['password_changed', 10], ['last_access', 11]
      ]
    end

    def column_headers
      column_order.map { |name, _| User.human_attribute_name name }
    end

    def column_widths
      column_order.map { |_, width| pdf.percent_width width }
    end

    def save
      pdf.custom_save_as pdf_name, User.table_name
    end

    def pdf_name
      I18n.t 'user.pdf.pdf_name'
    end
end
