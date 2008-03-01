module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Numeric #:nodoc:
      module BusinessTime
        # Reads best without arguments:  10.minutes.ago_in_business
        def ago_in_business(time = ::Time.now)
          result = time - self - weekend_days_between_ago(time - self, time)

          result -= 1.day while(in_weekend?(result))

          result
        end

        # Reads best with argument:  10.minutes.until_in_business(time)
        alias :until_in_business :ago_in_business

        # Reads best with argument:  10.minutes.since_in_business(time)
        def since_in_business(time = ::Time.now)
          result = time + self + weekend_days_between_since(time, time + self)

          result += 1.day while(in_weekend?(result))

          result
        end

        # Reads best without arguments:  10.minutes.from_now_in_business
        alias :from_now_in_business :since_in_business

        private

        def weekend_days_between_ago(start_date, end_date)
          weekend_days = 0
          swap = start_date > end_date
          start_date, end_date = end_date, start_date if swap

          begin
            if end_date.wday == 0 || end_date.wday == 6
              increment = end_date.wday == 0 ? 2 : 1
              end_date -= increment.days
              start_date -= increment.days
              weekend_days += increment
            end

            end_date -= 1.day
          end while start_date < end_date

          (swap ? -weekend_days : weekend_days) * 1.day
        end

        def weekend_days_between_since(start_date, end_date)
          weekend_days = 0
          swap = start_date > end_date
          start_date, end_date = end_date, start_date if swap

          begin
            if start_date.wday == 0 || start_date.wday == 6
              increment = start_date.wday == 0 ? 1 : 2
              end_date += increment.days
              start_date += increment.days
              weekend_days += increment
            end

            start_date += 1.day
          end while start_date <= end_date

          (swap ? -weekend_days : weekend_days) * 1.day
        end

        def in_weekend?(date)
          date.wday == 0 || date.wday == 6
        end
      end
    end
  end
end