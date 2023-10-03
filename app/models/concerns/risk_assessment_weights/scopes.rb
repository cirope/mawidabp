module RiskAssessmentWeights::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order identifier: :asc }
  end
end
