class TimeSummaryController < ApplicationController
  respond_to :html, :csv

  before_action :auth, :check_privileges, :set_title

  def index
    @start_date         = start_date
    @end_date           = end_date
    @work_hours_per_day = work_hours_per_day
    set_descendants
    set_user
    set_items

    respond_to do |format|
      format.html 
      format.csv {
        render csv: time_summary_csv, filename: "prueba.csv"
      }
    end
  end

  def new
    @time_consumption = TimeConsumption.new date: params[:date]
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

  private

    def time_consumption_params
      params.require(:time_consumption).permit :amount, :date, :activity_id
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

      set_resource_utilization
      set_time_consumption
    end

    def set_resource_utilization
      resource_utilizations.each do |ru|
        split_resource(ru).each do |date, rh|
          if date.between?(@start_date, @end_date)
            @items[date] ||= []
            @items[date]  << [rh.first, rh.last]
          end
        end
      end
    end

    def set_time_consumption
      @auth_user.time_consumptions.between(@start_date, @end_date).each do |tc|
        @items[tc.date] ||= []
        @items[tc.date]  << [tc.activity, tc.amount]
      end
    end

    def resource_utilizations
      parameters = [@start_date, @end_date].each_with_index.inject({}) do |acc, di|
        acc.merge :"start_#{di.last}" => di.first, :"end_#{di.last}" => di.first
      end

      conditions = 2.times.map do |i|
        [
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'start'} <= :start_#{i}",
          "#{WorkflowItem.table_name}.#{WorkflowItem.qcn 'end'} >= :end_#{i}"
        ].join ' AND '
      end.map { |c| "(#{c})" }.join ' OR '

      @user.
        resource_utilizations.
        joins(:workflow_item).
        references(:workflow_items).
        where(conditions, parameters)
    end

    def split_resource resource_utilization
      hours_per_day = {}
      wi            = resource_utilization.resource_consumer
      units         = resource_utilization.units

      (wi.start..wi.end).each do |date|
        if date.workday? && units > 0
          if units >= @work_hours_per_day
            hours_per_day[date] = [wi, @work_hours_per_day]
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
      if params[:user_id]
        @user = User.list.find(params[:user_id])
      else
        @user =  @auth_user
      end
    end

    def set_descendants
      @self_and_descendants = @auth_user.descendants + [@auth_user]
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
       t('time_summary.date'),
       t('time_summary.task'),
       t('time_summary.quantity_hours_per_day')
     ]
   end

   def time_summary_data_csv
     row = []

     (@start_date..@end_date).each do |date|
       if date.workday?
         if @items[date].present?
           @items[date].each do |item, hours|
            row << [date, item[:task], hours]
           end
         else
            row << [date, '', 0]
         end
       end
     end

     row
   end
end
