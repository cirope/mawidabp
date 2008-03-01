module PeriodsHelper
  def show_period_with_dates_as_acronym(period)
    content_tag :acronym, period.number,
      :title => "#{period.dates_range_text(false)}"
  end
end