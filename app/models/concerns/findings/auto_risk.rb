module Findings::AutoRisk
  extend ActiveSupport::Concern

  included do
    before_validation :assign_auto_risk, if: :automatic_risk?

    PROBABILITIES = {
      rare:           1,
      unlikely:       2,
      possible:       3,
      probable:       4,
      almost_certain: 5
    }

    IMPACT_RISKS = {
      small:    1,
      low:      2,
      moderate: 3,
      high:     4,
      critical: 5
    }
  end

  def automatic_risk?
    !manual_risk
  end

  module ClassMethods
    def auto_risk_thresholds
      {
        risks[:low]    => 4,
        risks[:medium] => 10,
        risks[:high]   => 100
      }
    end

    def probabilities
      PROBABILITIES
    end

    def impact_risks
      IMPACT_RISKS
    end
  end

  private

    def assign_auto_risk
      if probability && impact_risk
        result  = probability * impact_risk
        risk, _ = self.class.auto_risk_thresholds.detect do |_, threshold|
          result <= threshold
        end

        self.risk = risk
      else
        self.risk = nil
      end
    end
end
