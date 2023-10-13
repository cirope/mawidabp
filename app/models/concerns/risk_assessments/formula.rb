module RiskAssessments::Formula
  extend ActiveSupport::Concern

  included do
    before_validation :set_formula
  end

  private

    def set_formula
      self.formula ||= risk_assessment_template&.formula
    end
end
