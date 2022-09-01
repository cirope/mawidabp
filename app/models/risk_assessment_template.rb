class RiskAssessmentTemplate < ApplicationRecord
  include Auditable
  include RiskAssessmentTemplates::Clone
  include RiskAssessmentTemplates::DestroyValidation
  include RiskAssessmentTemplates::Scopes
  include RiskAssessmentTemplates::Search
  include RiskAssessmentTemplates::Validations
  include RiskAssessmentTemplates::Weights

  belongs_to :organization
  has_many :risk_assessments, dependent: :destroy

  def to_s
    name
  end
end
