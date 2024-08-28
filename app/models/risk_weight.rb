class RiskWeight < ApplicationRecord
  include Auditable
  include RiskWeights::Relations
  include RiskWeights::Validations

  delegate :identifier, to: :risk_assessment_weight

  def name
    risk_assessment_weight&.name
  end
end
