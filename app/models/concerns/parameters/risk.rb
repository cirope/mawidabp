module Parameters::Risk
  extend ActiveSupport::Concern

  RISK_TYPES = {
    low: 0,
    medium: 1,
    high: 2
  }

  module ClassMethods
    def risks
      types = JSON.parse ENV['RISK_TYPES'] || '{}'

      RISK_TYPES.merge! types.symbolize_keys
    end

    def risks_values
      risks.values
    end

    def highest_risks
      [RISK_TYPES[:high]]
    end
  end
end
