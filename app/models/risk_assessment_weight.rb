class RiskAssessmentWeight < ApplicationRecord
  include Auditable
  include RiskAssessmentWeights::Scopes
  include RiskAssessmentWeights::Validations
  include RiskAssessmentWeights::Relations

  attribute :heatmap, :boolean
end
