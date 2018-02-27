module Plans::StatsHelper
  def plan_stat_months
    current = Time.zone.today.at_end_of_month
    cursor  = @plan.period.start.at_end_of_month
    ending  = @plan.period.end.at_end_of_month
    list    = [
      active: params[:until] == Time.zone.today.to_s(:db),
      label:  t('.now'),
      value:  Time.zone.today.to_s(:db)
    ]

    while cursor <= ending
      list << {
        active: params[:until] == cursor.to_s(:db),
        label:  l(cursor, format: '%b %y'),
        value:  cursor.to_s(:db)
      }

      cursor = cursor.advance(months: 1).at_end_of_month
    end

    list
  end

  def plan_stat_concluded_count plan_items
    planned   = plan_stat_planned plan_items
    concluded = planned.select do |plan_item|
      plan_item.concluded? date_options
    end

    concluded.size
  end

  def plan_stat_progress plan_items
    total     = plan_items.size
    concluded = plan_stat_concluded_count plan_items
    progress  = total > 0 ? concluded.to_f / total * 100 : 0

    {
      label: '%.0f%%' % progress,
      value: progress.round,
      class: class_for_progress(progress)
    }
  end

  def plan_stat_planned plan_items
    plan_items.select do |plan_item|
      plan_item.start <= limit_date
    end
  end

  def plan_stat_on_time plan_items
    items = plan_stat_planned plan_items

    items.select do |plan_item|
      plan_item.concluded?(date_options) ||
        (plan_item.executed?(date_options) && plan_item.on_time?(date_options))
    end
  end

  def plan_stat_compliance plan_items
    compliance = 100
    items      = plan_stat_planned plan_items
    on_time    = plan_stat_on_time plan_items
    compliance = on_time.size.to_f / items.size * 100 if items.size > 0

    '%.0f%%' % compliance
  end

  def link_to_planned_items business_unit_type, plan_items
    planned_count = plan_stat_planned(plan_items).size
    show_link     = business_unit_type && planned_count > 0
    url           = [@plan, {
      business_unit_type: business_unit_type,
      until:              params[:until]
    }]

    link_to_if show_link, planned_count, url, data: { remote: true }
  end

  private

    def limit_date
      @until || Time.zone.today
    end

    def date_options
      @until ? { on: @until } : {}
    end

    def class_for_progress progress
      if progress == 100
        'success'
      elsif progress >= 80
        'warning'
      else
        'danger'
      end
    end
end
