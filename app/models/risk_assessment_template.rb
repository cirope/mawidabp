class RiskAssessmentTemplate < ApplicationRecord
  include Auditable
  include RiskAssessmentTemplates::Scopes
  include RiskAssessmentTemplates::Search
  include RiskAssessmentTemplates::Validations
  include RiskAssessmentTemplates::Weights

  belongs_to :organization
  has_many :risk_assessments, dependent: :destroy
end
