module Plans::Costs
  extend ActiveSupport::Concern

  def estimated_amount business_unit_type = nil
    items = business_unit_type ?
      plan_items.for_business_unit_type(business_unit_type) :
      plan_items

    items.inject(0.0) do |sum, plan_item|
      sum + plan_item.resource_utilizations.to_a.sum(&:cost)
    end
  end

  def cost
    plan_items.to_a.sum &:cost
  end
end
