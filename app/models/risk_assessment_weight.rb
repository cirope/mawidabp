class RiskAssessmentWeight < ApplicationRecord
  include Auditable
  include RiskAssessmentWeights::Validations

  belongs_to :risk_assessment_template
end
