module Periods::Months
  extend ActiveSupport::Concern

  def months
    cursor = start.at_end_of_month
    ending = self.end.at_end_of_month
    months = []

    while cursor <= ending
      months << cursor

      cursor = cursor.advance(months: 1).at_end_of_month
    end

    months
  end
end
