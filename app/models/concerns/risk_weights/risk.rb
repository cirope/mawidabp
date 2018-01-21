module RiskWeights::Risk
  extend ActiveSupport::Concern

  included do
    RISK_TYPES = {
      none:        0,
      low:         1,
      medium_low:  2,
      medium:      3,
      medium_high: 4,
      high:        5
    }
  end

  module ClassMethods
    def risks
      RISK_TYPES
    end

    def risks_values
      RISK_TYPES.values
    end
  end
end
