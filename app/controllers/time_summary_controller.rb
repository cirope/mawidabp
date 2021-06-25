class TimeSummaryController < ApplicationController
  respond_to :html, :csv

  before_action :auth, :check_privileges, :set_title, :set_descendants,
                :set_user
  before_action :set_time, only: [:edit, :update]

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
                                            limit: params[:limit]
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

    def set_time
      @time_consumption = TimeConsumption.find params[:id]
    end

    def time_consumption_params
      params.require(:time_consumption).permit :amount, :date, :limit, :activity_id
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
      @items = {}

      load_resource_utilizations
      set_time_consumption
      set_resource_utilization
    end

    def set_resource_utilization
      @_resource_utilizations.find_each do |ru|
        split_resource(ru).each do |date, rh|
          if date.between?(@start_date, @end_date)
            @items[date] ||= []
            @items[date]  << [rh.first, rh.last]
          end
        end
      end
    end

    def set_time_consumption
      start_col    = "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'start'}"
      end_col      = "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'end'}"
      r_start_date = @_resource_utilizations.reorder(start_col).first&.workflow_item&.start
      r_end_date   = @_resource_utilizations.reorder(end_col).last&.workflow_item&.end
      start_date   = r_start_date&.<(@start_date) ? r_start_date : @start_date
      end_date     = r_end_date&.>(@end_date) ? r_end_date : @end_date

      @user.time_consumptions.between(start_date, end_date).each do |tc|
        @items[tc.date] ||= []
        @items[tc.date]  << [tc.activity, tc.amount, tc.id]
      end
    end

    def load_resource_utilizations
      initial_parameters = { start: @start_date, end: @end_date }
      dates              = [@start_date, @end_date]

      parameters = dates.each_with_index.inject(initial_parameters) do |acc, di|
        acc.merge :"start_#{di.last}" => di.first, :"end_#{di.last}" => di.first
      end

      conditions = [
        [
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'start'} >= :start",
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'end'} <= :end"
        ].join(' AND ')
      ]

      2.times do |i|
        conditions << [
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'start'} <= :start_#{i}",
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'end'} >= :end_#{i}"
        ].join(' AND ')
      end

      conditions = conditions.map { |c| "(#{c})" }.join ' OR '

      @_resource_utilizations = @user.
        resource_utilizations.
        includes(:workflow_item).
        references(:workflow_items).
        where(conditions, parameters)
    end

    def split_resource resource_utilization
      hours_per_day = {}
      wi            = resource_utilization.resource_consumer
      units         = resource_utilization.units

      (wi.start..wi.end).each do |date|
        used      = Array(@items[date]).sum { |_item, hours| hours }
        remaining = @work_hours_per_day - used

        if date.workday? && units > 0
          if units >= remaining
            hours_per_day[date] = [wi, remaining]
          else
            hours_per_day[date] = [wi, units]
          end

          units -= hours_per_day[date].last
        end
      end

      hours_per_day
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
        t('time_summary.downloads.csv.quantity_hours_per_day')
      ]
    end

    def time_summary_data_csv
      row = []

      (@start_date..@end_date).each do |date|
        if date.workday?
          if @items[date].present?
            @items[date].each do |item, hours|
              row << [
                date,
                item.to_s,
                helpers.number_with_precision(hours, precision: 1)
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
