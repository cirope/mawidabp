class RiskAssessmentTemplate < ApplicationRecord
  include Auditable
  include RiskAssessmentTemplates::Scopes
  include RiskAssessmentTemplates::Search
  include RiskAssessmentTemplates::Validations
  include RiskAssessmentTemplates::Weights

  belongs_to :organization
end
