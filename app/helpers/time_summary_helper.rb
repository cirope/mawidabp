module TimeSummaryHelper
  def time_summary_prev_week_path
    time_summary_path start_date: @start_date.weeks_ago(1),
                      end_date:   @end_date.weeks_ago(1)
  end

  def time_summary_next_week_path
    time_summary_path start_date: @start_date.weeks_since(1),
                      end_date:   @end_date.weeks_since(1)
  end

  def time_summary_items_for date
    @items[date]
  end
end
