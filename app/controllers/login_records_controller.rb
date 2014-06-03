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

    respond_to do |format|
      format.html { @login_records = @login_records.page(params[:page]) }
      format.pdf {
        redirect_to LoginRecordPdf.new(
          @from_date, @to_date, @login_records, current_organization
        ).generate
      }
    end
  end

  # GET /login_records/1
  def show
    respond_with @login_record
  end

  private

    def set_login_record
      @login_record = LoginRecord.list.find params[:id]
    end

    def load_privileges
      @action_privileges.update choose: :read
    end

    def conditions
      @from_date, @to_date = *make_date_range(params[:search] || params[:index])

      unless params[:search]
        default_conditions = [
          "#{LoginRecord.table_name}.created_at BETWEEN :from_date AND :to_date",
          from_date: @from_date.to_time.at_beginning_of_day,
          to_date: @to_date.to_time.at_end_of_day
        ]
      end

      build_search_conditions LoginRecord, default_conditions
    end
end
