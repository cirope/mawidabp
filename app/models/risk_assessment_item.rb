class RiskAssessmentItem < ApplicationRecord
  include Auditable
  include RiskAssessmentItems::Risk
  include RiskAssessmentItems::Validations

  belongs_to :risk_assessment, optional: true
  belongs_to :business_unit, optional: true
  belongs_to :process_control, optional: true
  has_one :business_unit_type, through: :business_unit
end
