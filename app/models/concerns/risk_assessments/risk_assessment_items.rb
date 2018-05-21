module RiskAssessments::RiskAssessmentItems
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_items, -> { order :order }, dependent: :destroy,
      inverse_of: :risk_assessment
    has_many :best_practices, through: :risk_assessment_items
    has_many :business_unit_types, through: :risk_assessment_items

    accepts_nested_attributes_for :risk_assessment_items, allow_destroy: true, reject_if: :all_blank
    validates_associated :risk_assessment_items, if: :final?
  end

  def build_items_from_best_practices ids
    items = []

    BestPractice.list.where(id: ids).each do |bp|
      bp.process_controls.where(obsolete: false).each do |pc|
        rai = risk_assessment_items.new(name: pc.name, process_control_id: pc.id)

        rai.build_risk_weights

        items << rai
      end
    end

    items
  end

  def build_items_from_business_unit_types ids
    items = []

    BusinessUnitType.list.where(id: ids).each do |but|
      but.business_units.each do |bu|
        rai = risk_assessment_items.new(name: bu.name, business_unit_id: bu.id)

        rai.build_risk_weights

        items << rai
      end
    end

    items
  end
end
