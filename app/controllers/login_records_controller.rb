class LoginRecordsController < ApplicationController
  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_login_record, only: [:show]
  before_action :set_title

  # GET /login_records/choose
  def choose
  end

  # GET /login_records
  def index
    @from_date, @to_date = *make_date_range(params[:index])

    default_conditions = [
      "#{LoginRecord.table_name}.created_at BETWEEN :from_date AND :to_date",
      from_date: @from_date, to_date: @to_date.to_time.end_of_day
    ] unless params[:search]

    build_search_conditions LoginRecord, default_conditions
    @login_records = LoginRecord.between(@conditions).page params[:page]

    if @login_records.size == 1 && !@query.blank? && !params[:page]
      redirect_to login_record_url(@login_records.first)
    end
  end

  # GET /login_records/1
  def show
    respond_with @login_record
  end

  # GET /login_records/export_to_pdf
  def export_to_pdf
    from_date, to_date = *make_date_range(params[:range])
    login_records = LoginRecord.list.includes(:user).where(
      [
        'created_at BETWEEN :from_date AND :to_date',
        {
          :from_date => from_date,
          :to_date => to_date.to_time.end_of_day
        }
      ]
    ).order('start DESC')

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization
    pdf.add_title t('login_record.index_title')

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(t('login_record.period.title'),
      t('login_record.period.range',
        :from_date => l(from_date, :format => :long),
        :to_date => l(to_date, :format => :long)))

    column_order = [['user_id', 20], ['start', 15], ['end', 15], ['data', 50]]
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_name, col_with|
      column_headers << LoginRecord.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_with)
    end

    login_records.each do |login_record|
      column_data << [
        "<b>#{login_record.user.user}</b>",
        login_record.start ?
          l(login_record.start, :format => :minimal) : '-',
        login_record.end ?
          l(login_record.end, :format => :minimal) : '-',
        login_record.data
      ]
    end

    unless column_data.blank?
      pdf.move_down PDF_FONT_SIZE
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf_name = t('login_record.pdf_list_name',
      :from_date => from_date.to_formatted_s(:db),
      :to_date => to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, LoginRecord.table_name)

    redirect_to Prawn::Document.relative_path(pdf_name, LoginRecord.table_name)
  end

  private

    def set_login_record
      @login_record = LoginRecord.list.find params[:id]
    end

    def load_privileges
      @action_privileges.update choose: :read, export_to_pdf: :read
    end
end
