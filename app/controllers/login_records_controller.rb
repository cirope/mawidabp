# =Controlador de registros de ingreso
#
# Lista y muestra registros de ingreso (#LoginRecord)
class LoginRecordsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges

  # Muestra un menú con los distintos listados disponibles (registros de ingreso
  # y registros de errores)
  #
  # * GET /login_records/choose
  def choose
    @title = t :'login_record.choose'
    
    respond_to do |format|
      format.html # choose.html.erb
    end
  end

  # Lista los registros de ingreso
  #
  # * GET /login_records
  # * GET /login_records.xml
  def index
    @title = t :'login_record.index_title'
    @from_date, @to_date = *make_date_range(params[:index])
    default_conditions = [
      'organization_id = :organization_id',
      {:organization_id => @auth_organization.id}
    ]

    unless params[:search]
      default_conditions[0] = [
        default_conditions[0],
        'created_at BETWEEN :from_date AND :to_date'
      ].join(' AND ')

      default_conditions[1].merge!(:from_date => @from_date,
        :to_date => @to_date.to_time.end_of_day)
    else
      build_search_conditions LoginRecord, default_conditions
    end

    @login_records = LoginRecord.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => :user,
      :conditions => @conditions || default_conditions,
      :order => 'start DESC'
    )

    respond_to do |format|
      format.html {
        if @login_records.size == 1 && !@query.blank?
          redirect_to login_record_path(@login_records.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @login_records }
    end
  end

  # Muestra el detalle de un registro de ingreso
  #
  # * GET /login_records/1
  # * GET /login_records/1.xml
  def show
    @title = t :'login_record.show_title'
    @login_record = LoginRecord.first(
      :conditions => {
        :id => params[:id], :organization_id => @auth_organization.id
      }
    )

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @login_record }
    end
  end

  # Lista de registros de ingreso en PDF
  #
  # * GET /login_records/export_to_pdf
  def export_to_pdf
    from_date, to_date = *make_date_range(params[:range])
    login_records = LoginRecord.all(
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
      :order => 'start DESC'
    )

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title t(:'login_record.index_title')

    pdf.move_pointer 12

    pdf.add_description_item(t(:'login_record.period.title'),
      t(:'login_record.period.range',
        :from_date => l(from_date, :format => :long),
        :to_date => l(to_date, :format => :long)))

    column_order = [['user_id', 20], ['start', 15], ['end', 15], ['data', 50]]
    columns = {}
    column_data = []

    column_order.each do |col_name, col_with|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = LoginRecord.human_attribute_name col_name
        c.width = pdf.percent_width col_with
      end
    end

    login_records.each do |login_record|
      column_data << {
        'user_id' => "<b>#{login_record.user.user}</b>".to_iso,
        'start' => login_record.start ?
          l(login_record.start, :format => :minimal).to_iso : '-',
        'end' => login_record.end ?
          l(login_record.end, :format => :minimal).to_iso : '-',
        'data' => login_record.data.to_iso
      }
    end

    unless column_data.blank?
      pdf.move_pointer 12

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

    pdf_name = t(:'login_record.pdf_list_name',
      :from_date => from_date.to_formatted_s(:db),
      :to_date => to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, LoginRecord.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, LoginRecord.table_name)
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
        :choose => :read,
        :export_to_pdf => :read
      })
  end
end