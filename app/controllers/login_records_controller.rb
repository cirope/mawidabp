class LoginRecordsController < ApplicationController
  respond_to :html, :pdf

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_login_record, only: [:show]
  before_action :set_title

  # GET /login_records/choose
  def choose
  end

  # GET /login_records
  def index
    @login_records = LoginRecord.between conditions

    if request.format.pdf?
      @pdf = create_pdf
    end

    respond_to do |format|
      format.html { @login_records = @login_records.page(params[:page]) }
      format.pdf { redirect_to @pdf.relative_path }
    end
  end

  # GET /login_records/1
  def show
  end

  private

    def set_login_record
      @login_record = LoginRecord.list.find params[:id]
    end

    def load_privileges
      @action_privileges.update choose: :read
    end

    def conditions
      @from_date, @to_date = *make_date_range(params[:index])

      unless params[:search]
        default_conditions = [
          "#{LoginRecord.table_name}.created_at BETWEEN :from_date AND :to_date",
          from_date: @from_date.to_time.at_beginning_of_day,
          to_date: @to_date.to_time.at_end_of_day
        ]
      end

      build_search_conditions LoginRecord, default_conditions
    end

    def create_pdf
      LoginRecordPdf.new(
        from: @from_date, to: @to_date, login_records: @login_records,
        current_organization: current_organization
      )
    end
end
