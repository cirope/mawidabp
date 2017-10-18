module Reviews::PlanItem
  extend ActiveSupport::Concern

  included do
    belongs_to :plan_item
    has_one :business_unit, through: :plan_item
  end

  def external_audit?
    business_unit.business_unit_type.external
  end

  def internal_audit?
    !external_audit?
  end
end
