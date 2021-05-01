module TimeSummaryHelper
  def time_summary_prev_week_path
    time_summary_index_path start_date: @start_date.weeks_ago(1),
                            end_date:   @end_date.weeks_ago(1)
  end

  def time_summary_next_week_path
    time_summary_index_path start_date: @start_date.weeks_since(1),
                            end_date:   @end_date.weeks_since(1)
  end

  def time_summary_completed? date
    total = Array(@items[date]).sum { |_item, hours| hours }

    total >= @work_hours_per_day
  end
end
