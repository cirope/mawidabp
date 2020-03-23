class ErrorRecordsController < ApplicationController
  respond_to :html, :pdf

  before_action :auth, :check_privileges
  before_action :set_error_record, only: [:show]
  before_action :set_title

  # * GET /error_records
  def index
    @error_records = ErrorRecord.list.includes(:user).search(
      default_conditions: filtered_by_dates,
      **search_params
    ).default_order.references :user

    respond_to do |format|
      format.html { @error_records = @error_records.page params[:page] }
      format.pdf { redirect_to pdf.relative_path }
    end
  end

  # * GET /error_records/1
  def show
  end

  private

    def set_error_record
      @error_record = ErrorRecord.list.find params[:id]
    end

    def pdf
      ErrorRecordPdf.new(
        from: @from_date,
        to: @to_date,
        error_records: @error_records,
        current_organization: current_organization
      )
    end

    def filtered_by_dates
      @from_date, @to_date = *make_date_range(params[:index])

      if params[:search].blank?
        [
          "#{ErrorRecord.quoted_table_name}.#{ErrorRecord.qcn('created_at')} BETWEEN :from_date AND :to_date",
          from_date: @from_date.to_time.at_beginning_of_day,
          to_date: @to_date.to_time.at_end_of_day
        ]
      end
    end
end
