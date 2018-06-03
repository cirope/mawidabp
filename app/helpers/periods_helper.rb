module PeriodsHelper
  def show_period_with_dates_as_abbr(period)
    content_tag :abbr, period.name,
      title: "#{period.dates_range_text(false)}"
  end
end
