class RiskWeight < ApplicationRecord
  include Auditable
  include RiskWeights::Identifier
  include RiskWeights::Relations
  include RiskWeights::Risk
  include RiskWeights::Validations

  def name
    risk_assessment_weight&.name
  end
end
