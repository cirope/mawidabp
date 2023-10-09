module RiskWeights::Identifier
  extend ActiveSupport::Concern

  included do
    before_validation :set_identifier
  end

  private

    def set_identifier
      self.identifier = risk_assessment_weight&.identifier
    end
end
