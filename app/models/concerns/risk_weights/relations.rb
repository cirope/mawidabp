module RiskWeights::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :risk_assessment_weight, optional: true
    belongs_to :risk_assessment_item, optional: true

    has_many :risk_score_items, through: :risk_assessment_weight
    has_one :risk_assessment_template, through: :risk_assessment_weight
  end
end
