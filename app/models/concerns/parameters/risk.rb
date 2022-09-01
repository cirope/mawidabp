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
      [RISK_TYPES[:high]]
    end

    private

      def risk_types
        if USE_SCOPE_CYCLE
          { none: 0, low: 1, medium: 2, high: 3 }
        else
          { low: 0, medium: 1, high: 2 }
        end
      end
  end
end
