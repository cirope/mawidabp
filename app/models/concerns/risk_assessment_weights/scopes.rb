module RiskAssessmentWeights::Scopes
  extend ActiveSupport::Concern

  included do
    delegate :formula, to: :risk_assessment_template, allow_nil: false

    scope :ordered,  -> { order id: :asc }
    scope :heatmaps, -> { where heatmap: true }
  end
end
