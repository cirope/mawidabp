module RiskAssessments::RiskAssessmentItems
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_items, -> { order :order }, dependent: :destroy

    accepts_nested_attributes_for :risk_assessment_items, allow_destroy: true, reject_if: :all_blank
  end
end
