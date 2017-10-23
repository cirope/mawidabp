module Parameters::Risk
  extend ActiveSupport::Concern

  included do
    ::RISK_TYPES = risk_types unless defined? ::RISK_TYPES
  end

  module ClassMethods
    def risks
      RISK_TYPES
    end

    def risks_values
      RISK_TYPES.values
    end

    def highest_risks
      if SHOW_EXTENDED_RISKS
        [RISK_TYPES[:high], RISK_TYPES[:high_medium], RISK_TYPES[:medium_high]]
      else
        [RISK_TYPES[:high]]
      end
    end

    private

      def risk_types
        if SHOW_EXTENDED_RISKS
          {
            not_relevant: 0,
            low:          1,
            medium:       2,
            medium_high:  3,
            high_medium:  4,
            high:         5
          }
        else
          { low: 0, medium: 1, high: 2 }
        end
      end
  end
end
