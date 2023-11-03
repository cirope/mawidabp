class RiskAssessmentWeight < ApplicationRecord
  include Auditable
  include RiskAssessmentWeights::Scopes
  include RiskAssessmentWeights::Relations
  include RiskAssessmentWeights::Validations

  attribute :heatmap, :boolean
end
