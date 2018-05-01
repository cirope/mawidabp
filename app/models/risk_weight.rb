class RiskWeight < ApplicationRecord
  include Auditable
  include RiskWeights::Risk
  include RiskWeights::Validations

  belongs_to :risk_assessment_weight, optional: true
  belongs_to :risk_assessment_item, optional: true

  def name
    risk_assessment_weight&.name
  end
end
