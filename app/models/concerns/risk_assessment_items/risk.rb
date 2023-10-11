module RiskAssessmentItems::Risk
  extend ActiveSupport::Concern

  included do
    before_save :calculate_risk
  end

  private

    def calculate_risk
      result = formula.dup
      values = risk_weights.map { |rw| [rw.identifier, rw.value] }

      values.to_h.each { |k,v| result.gsub! k, v.to_s }

      self.risk = eval(result).round
    end
end
