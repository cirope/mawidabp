module Parameters::Risk
  extend ActiveSupport::Concern

  RISK_TYPES = { low: 0, medium: 1, high: 2 }

  module ClassMethods
    def risks
      RISK_TYPES
    end

    def risks_values
      RISK_TYPES.values
    end
  end
end
