class RiskWeight < ApplicationRecord
  include Auditable
  include RiskWeights::Risk
  include RiskWeights::Validations

  belongs_to :risk_assessment_weight
  belongs_to :risk_assessment_item

  def name
    risk_assessment_weight&.name
  end
end
