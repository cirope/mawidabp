class RiskAssessmentItem < ApplicationRecord
  include Auditable
  include RiskAssessmentItems::Risk
  include RiskAssessmentItems::Validations
  include RiskAssessmentItems::Weights

  belongs_to :risk_assessment, optional: true
  belongs_to :business_unit, optional: true
  belongs_to :process_control, optional: true
  has_one :business_unit_type, through: :business_unit
  has_one :best_practice, through: :process_control
end
