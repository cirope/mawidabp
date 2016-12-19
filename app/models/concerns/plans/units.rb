module Plans::Units
  extend ActiveSupport::Concern

  def estimated_amount business_unit_type = nil
    items = plan_items.for_business_unit_type business_unit_type

    items.inject 0.0 do |sum, plan_item|
      sum + plan_item.resource_utilizations.to_a.sum(&:units)
    end
  end

  def units
    plan_items.to_a.sum &:units
  end
end
