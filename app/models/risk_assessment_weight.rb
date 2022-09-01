class RiskAssessmentWeight < ApplicationRecord
  include Auditable
  include RiskAssessmentWeights::Validations

  belongs_to :risk_assessment_template
  has_many :risk_weights, dependent: :destroy
end
