module RiskAssessmentItems::Risk
  extend ActiveSupport::Concern

  included do
    before_save :calculate_risk
  end

  private

    def calculate_risk
      max_risk_weight = RiskWeight.risks_values.last

      max_risk  = risk_weights.sum { |rw| rw.weight.to_f * max_risk_weight }
      risk_sum  = risk_weights.sum { |rw| rw.value.to_f * rw.weight }

      self.risk = (risk_sum / max_risk * 100).round if max_risk > 0
    end
end
