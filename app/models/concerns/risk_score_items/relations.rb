module RiskScoreItems::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :risk_assessment_weight
  end
end
