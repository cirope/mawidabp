module Parameters::Risk
  extend ActiveSupport::Concern

  included do
    RISK_TYPES = { low: 0, medium: 1, high: 2 }
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
