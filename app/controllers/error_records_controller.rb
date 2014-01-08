class ErrorRecordsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges

  # Lista los registros de error
  #
  # * GET /error_records
  # * GET /error_records.xml
  def index
    @title = t 'error_record.index_title'
    @from_date, @to_date = *make_date_range(params[:index])

    unless params[:search]
      default_conditions = [
        "#{ErrorRecord.table_name}.created_at BETWEEN :from_date AND :to_date",
        { from_date: @from_date, to_date: @to_date.to_time.end_of_day }
      ]
    else
      build_search_conditions ErrorRecord
    end

    @error_records = ErrorRecord.list.includes(:user).where(
      @conditions || default_conditions
    ).order("#{ErrorRecord.table_name}.created_at DESC").page(
      params[:page]
    ).references(:users)

    respond_to do |format|
      format.html {
        if @error_records.size == 1 && !@query.blank? && !params[:page]
          redirect_to error_record_path(@error_records.first)
        end
      } # index.html.erb
      format.xml  { render xml: @error_records }
    end
  end

  # Muestra el detalle de un registro de error
  #
  # * GET /error_records/1
  # * GET /error_records/1.xml
  def show
    @title = t 'error_record.show_title'
    @error_record = ErrorRecord.list.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @error_record }
    end
  end

  # Lista de registros de error en PDF
  #
  # * GET /error_records/export_to_pdf
  def export_to_pdf
    from_date, to_date = *make_date_range(params[:range])
    error_records = ErrorRecord.list.includes(:user).where(
      [
        'created_at BETWEEN :from_date AND :to_date',
        {
          from_date: from_date,
          to_date: to_date.to_time.end_of_day
        }
      ]
    ).order('created_at DESC')

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization
    pdf.add_title t('error_record.index_title')

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(t('error_record.period.title'),
      t('error_record.period.range',
        from_date: l(from_date, format: :long),
        to_date: l(to_date, format: :long)))

    column_order = [['user_id', 20], ['created_at', 15], ['error', 15],
      ['data', 50]]
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_name, col_with|
      column_headers << ErrorRecord.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_with)
    end

    error_records.each do |error_record|
      user_name = error_record.user.try(:user) || t('error_record.void_user')

      column_data << [
        "<b>#{user_name}</b>",
        error_record.created_at ?
          l(error_record.created_at, format: :minimal) : '-',
        error_record.error_text,
        error_record.data
      ]
    end

    pdf.move_down PDF_FONT_SIZE

    unless column_data.blank?
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

    pdf_name = t('error_record.pdf_list_name',
      from_date: from_date.to_formatted_s(:db),
      to_date: to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, ErrorRecord.table_name)

    redirect_to Prawn::Document.relative_path(pdf_name, ErrorRecord.table_name)
  end

  private
    def load_privileges
      @action_privileges.update(export_to_pdf: :read)
    end
end
