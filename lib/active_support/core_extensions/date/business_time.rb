module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Date #:nodoc:
      module BusinessTime
        # Returns the difference between two dates in business days
        def diff_in_business(date)
          if date.respond_to?(:to_date)
            a, b = *([self, date.to_date].sort)
            days_in_weekend = 0

            until a == b
              days_in_weekend += 1 if in_weekend?(b)
              b -= 1
            end

            a, b = *([self, date.to_date].sort)

            (b - a - days_in_weekend) * (self >= date.to_date ? 1 : -1)
          else
            raise 'The argument must be an object with a to_date conversion method'
          end
        end

        private

        def in_weekend?(date)
          date.wday == 0 || date.wday == 6
        end
      end
    end
  end
end