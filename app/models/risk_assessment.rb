class RiskAssessment < ApplicationRecord
  include Auditable
  include RiskAssessments::RiskAssessmentItems
  include RiskAssessments::Scopes
  include RiskAssessments::Search
  include RiskAssessments::Validations

  belongs_to :period, optional: true
  belongs_to :risk_assessment_template, optional: true
  belongs_to :organization
end
