class TimeSummaryController < ApplicationController
  respond_to :html, :csv

  before_action :auth, :check_privileges, :set_title, :set_descendants,
                :set_user
  before_action :set_time_consumption, only: [:edit, :update]

  def index
    @start_date         = start_date
    @end_date           = end_date
    @work_hours_per_day = work_hours_per_day

    set_items

    respond_to do |format|
      format.html
      format.csv {
        render csv: time_summary_csv, filename: filename
      }
    end
  end

  def new
    @time_consumption = TimeConsumption.new date:  params[:date],
                                            limit: params[:limit],
                                            resource_on_type: params[:resource_on_type]
  end

  def create
    @time_consumption = TimeConsumption.new time_consumption_params.merge(
      user: @auth_user
    )
    @time_consumption.save

    respond_with @time_consumption, location: time_summary_index_url(
      start_date: @time_consumption.date.at_beginning_of_week,
      end_date:   @time_consumption.date.at_end_of_week
    )
  end

  def edit
  end

  def update
    update_resource @time_consumption, time_consumption_params

    respond_with @time_consumption, location: time_summary_index_url(
      start_date: @time_consumption.date.at_beginning_of_week,
      end_date:   @time_consumption.date.at_end_of_week
    )
  end

  private

    def set_time_consumption
      @time_consumption       = TimeConsumption.find params[:id]
      @time_consumption.limit = params[:limit]
    end

    def time_consumption_params
      params.require(:time_consumption).permit :amount, :date, :limit, :resource_on_id, :resource_on_type
    end

    def start_date
      if params[:start_date]
        Timeliness.parse(params[:start_date], zone: :local).to_date
      else
        Time.zone.today.at_beginning_of_week
      end
    end

    def end_date
      if params[:end_date]
        Timeliness.parse(params[:end_date], zone: :local).to_date
      else
        Time.zone.today.at_end_of_week
      end
    end

    def set_items
      @items        = {}
      @amount_hours = 0

      set_time_consumptions
    end

    def set_time_consumptions
      @user.time_consumptions.between(start_date, end_date).each do |tc|
        @items[tc.date] ||= []
        @items[tc.date]  << [tc.resource_on.to_s, tc.amount, tc.id]
        @amount_hours    += tc.amount
      end
    end

    def work_hours_per_day
      setting = current_organization.settings.find_by name: 'hours_of_work_per_day'
      value   = setting&.value.to_f

      value > 0 ? value : 8
    end

    def set_user
      if params[:user_id].present?
        @user = User.list.where(
          id: @auth_user.self_and_descendants
        ).find params[:user_id]
      else
        @user = @auth_user
      end
    end

    def set_descendants
      @self_and_descendants = @auth_user.self_and_descendants
    end

    def time_summary_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << time_summary_header_csv

        time_summary_data_csv.each do |data|
          csv << data
        end
      end

      "\uFEFF#{csv_str}"
    end

    def time_summary_header_csv
      [
        t('time_summary.downloads.csv.date'),
        t('time_summary.downloads.csv.task'),
        t('time_summary.downloads.csv.quantity_hours_per_day'),
        t('time_summary.downloads.csv.user')
      ]
    end

    def time_summary_data_csv
      row  = []
      data = {}

      @results = TimeConsumption.where(user: @self_and_descendants).
        where(date: @start_date..@end_date).each do |tc|
          data[tc.date] ||= []
          data[tc.date]  << [tc.resource_on.to_s, tc.amount, tc.user.full_name]
      end

      (@start_date..@end_date).each do |date|
        if date.workday?
          if data[date].present?
            data[date].each do |item, hours, user|
              row << [
                date,
                item.to_s,
                helpers.number_with_precision(hours, precision: 1),
                user
              ]
            end
          else
            row << [date, '', 0]
          end
        end
      end

      row
    end

    def filename
      [@user.name, @user.last_name].join '_'
    end
end
