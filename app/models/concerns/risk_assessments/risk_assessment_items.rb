module RiskAssessments::RiskAssessmentItems
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_items, -> { order :order }, dependent: :destroy
    has_many :best_practices, through: :risk_assessment_items

    accepts_nested_attributes_for :risk_assessment_items, allow_destroy: true, reject_if: :all_blank
  end

  def build_items_from_best_practices ids
    items = []

    BestPractice.where(id: ids).each do |bp|
      bp.process_controls.where(obsolete: false).each do |pc|
        rai = risk_assessment_items.new(name: pc.name, process_control_id: pc.id)

        rai.build_risk_weights

        items << rai
      end
    end

    items
  end
end
