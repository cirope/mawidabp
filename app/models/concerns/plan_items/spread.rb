module PlanItems::Spread
  extend ActiveSupport::Concern

  def month_beginnings
    distance_in_months = (self.end.year * 12 + self.end.month) -
                         (start.year    * 12 + start.month)

    distance_in_months.next.times.map do |i|
      start.at_beginning_of_month.advance months: i
    end
  end

  def month_spreads
    days = (self.end - start).to_i.next

    month_beginnings.each_with_object({}) do |month, spread|
      days_in_month = if start.beginning_of_month == self.end.beginning_of_month
                        days
                      elsif month == start.at_beginning_of_month
                        (month.at_end_of_month - start).to_i.next
                      elsif month == self.end.at_beginning_of_month
                        (self.end - month).to_i.next
                      else
                        (month.at_end_of_month - month).to_i.next
                      end

      spread[month] = (days_in_month.to_f / days).round(5)
    end
  end
end
