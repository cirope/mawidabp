module RiskAssessmentWeights::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :owner, polymorphic: true
    has_many :risk_weights, dependent: :destroy
    has_many :risk_score_items, dependent: :destroy

    accepts_nested_attributes_for :risk_score_items, allow_destroy: true, reject_if: :all_blank
  end
end
