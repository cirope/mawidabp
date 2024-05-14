module PeriodsHelper
  def show_period_with_dates_as_abbr(period)
    content_tag :abbr, period.name,
      :title => "#{period.dates_range_text(false)}"
  end

  def period_filter_options
    Period.list.map { |period| [period.name, period.id] }
  end
end
