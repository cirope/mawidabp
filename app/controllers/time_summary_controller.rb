class TimeSummaryController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges, :set_title

  def index
    @start_date = start_date
    @end_date   = end_date

    set_items
  end

  private

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

      resource_utilizations.each do |ru|
        split_resource(ru).each do |date, rh|
          if date.between?(@start_date, @end_date)
            items = @items[date] || []

            items << [rh.first, rh.last]

            @items[date] = items
          end
        end
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

      @auth_user.
        resource_utilizations.
        joins(:workflow_item).
        references(:workflow_items).
        where(conditions, parameters)
    end

    def split_resource resource_utilization
      hours_per_day      = {}
      work_hours_per_day = 7
      wi                 = resource_utilization.resource_consumer
      units              = resource_utilization.units

      (wi.start..wi.end).each do |date|
        if date.workday? && units > 0
          if units >= work_hours_per_day
            hours_per_day[date] = [wi, work_hours_per_day]
          else
            hours_per_day[date] = [wi, units]
          end

          units -= hours_per_day[date].last
        end
      end

      hours_per_day
    end
end
