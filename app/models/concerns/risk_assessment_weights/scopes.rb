module RiskAssessmentWeights::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered,  -> { order id: :asc }
  end
end
