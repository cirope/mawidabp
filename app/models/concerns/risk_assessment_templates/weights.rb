module RiskAssessmentTemplates::Weights
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_weights, dependent: :destroy

    accepts_nested_attributes_for :risk_assessment_weights, allow_destroy: true, reject_if: :all_blank
  end
end
