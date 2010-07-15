# =Controlador de registros de errores
#
# Lista y muestra registros de errores (#ErrorRecord)
class ErrorRecordsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges

  # Lista los registros de error
  #
  # * GET /error_records
  # * GET /error_records.xml
  def index
    @title = t :'error_record.index_title'
    @from_date, @to_date = *make_date_range(params[:index])
    default_conditions = [
      "#{ErrorRecord.table_name}.organization_id = :organization_id",
      {:organization_id => @auth_organization.id}
    ]

    unless params[:search]
      default_conditions[0] = [
        default_conditions[0],
        "#{ErrorRecord.table_name}.created_at BETWEEN :from_date AND :to_date"
      ].join(' AND ')

      default_conditions[1].merge!(:from_date => @from_date,
        :to_date => @to_date.to_time.end_of_day)
    else
      build_search_conditions ErrorRecord, default_conditions
    end

    @error_records = ErrorRecord.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => :user,
      :conditions => @conditions || default_conditions,
      :order => "#{ErrorRecord.table_name}.created_at DESC")

    respond_to do |format|
      format.html {
        if @error_records.size == 1 && !@query.blank? && !params[:page]
          redirect_to error_record_path(@error_records.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @error_records }
    end
  end

  # Muestra el detalle de un registro de error
  #
  # * GET /error_records/1
  # * GET /error_records/1.xml
  def show
    @title = t :'error_record.show_title'
    @error_record = ErrorRecord.first(
      :conditions => {
        :organization_id => @auth_organization.id, :id => params[:id]
      }
    )

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @error_record }
    end
  end

  # Lista de registros de error en PDF
  #
  # * GET /error_records/export_to_pdf
  def export_to_pdf
    from_date, to_date = *make_date_range(params[:range])
    error_records = ErrorRecord.all(
      :include => :user,
      :conditions => [
        [
          'organization_id = :organization_id',
          'created_at BETWEEN :from_date AND :to_date'
        ].join(' AND '),
        {
          :from_date => from_date,
          :to_date => to_date.to_time.end_of_day,
          :organization_id => @auth_organization.id
        }
      ],
      :order => 'created_at DESC'
    )

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title t(:'error_record.index_title')

    pdf.move_pointer 12

    pdf.add_description_item(t(:'error_record.period.title'),
      t(:'error_record.period.range',
        :from_date => l(from_date, :format => :long),
        :to_date => l(to_date, :format => :long)))

    column_order = [['user_id', 20], ['created_at', 15], ['error', 15],
      ['data', 50]]
    columns = {}
    column_data = []

    column_order.each do |col_name, col_with|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = ErrorRecord.human_attribute_name col_name
        c.width = pdf.percent_width col_with
      end
    end

    error_records.each do |error_record|
      user_name = error_record.user.try(:user) || t(:'error_record.void_user')
      
      column_data << {
        'user_id' => "<b>#{user_name}</b>".to_iso,
        'created_at' => error_record.created_at ?
          l(error_record.created_at, :format => :minimal).to_iso : '-',
        'error' => error_record.error_text.to_iso,
        'data' => error_record.data.to_iso
      }
    end

    pdf.move_pointer 12

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.map(&:first)
        table.split_rows = true
        table.font_size = 8
        table.shade_color = Color::RGB::Grey90
        table.shade_heading_color = Color::RGB::Grey70
        table.heading_font_size = 10
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    pdf_name = t(:'error_record.pdf_list_name',
      :from_date => from_date.to_formatted_s(:db),
      :to_date => to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, ErrorRecord.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, ErrorRecord.table_name)
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read
      })
  end
end