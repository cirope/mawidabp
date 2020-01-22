module Plans::CalendarHelper
  def month_in_weeks month
    cursor = month.at_beginning_of_month.at_beginning_of_week.to_date
    ending = month.at_end_of_month.at_beginning_of_week.to_date
    weeks  = []

    while cursor <= ending
      weeks << cursor.all_week

      cursor = cursor.advance weeks: 1
    end

    weeks
  end

  def business_unit_with_plan_items_in_week? business_unit, week
    @plan.plan_items.any? do |pi|
      if pi.business_unit_id == business_unit.id
        week.overlaps? (pi.start)..(pi.end)
      end
    end
  end

  def plan_items_sorted_for_calendar plan_items
    plan_items.sort_by do |pi|
      but_name = pi.business_unit_type&.name || 'ZZZ'
      bu_name  = pi.business_unit&.name      || 'ZZZ'

      [but_name, bu_name, pi.project].join('-').downcase
    end
  end
end
