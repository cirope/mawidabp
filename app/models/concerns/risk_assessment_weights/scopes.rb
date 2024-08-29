module RiskAssessmentWeights::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered,  -> { order id: :asc }
    scope :heatmaps, -> { where heatmap: true }
  end
end
