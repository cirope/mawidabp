class RiskAssessment < ApplicationRecord
  include Auditable
  include RiskAssessments::DestroyValidation
  include RiskAssessments::Plan
  include RiskAssessments::RiskAssessmentItems
  include RiskAssessments::Scopes
  include RiskAssessments::Search
  include RiskAssessments::UpdateCallbacks
  include RiskAssessments::Validations

  belongs_to :period, optional: true
  belongs_to :plan, optional: true
  belongs_to :risk_assessment_template, optional: true
  belongs_to :organization
end
