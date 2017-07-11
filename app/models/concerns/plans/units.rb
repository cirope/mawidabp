module Plans::Units
  extend ActiveSupport::Concern

  def estimated_amount business_unit_type = nil, on: Time.zone.today
    items = plan_items_on(on).for_business_unit_type business_unit_type

    items.inject 0.0 do |sum, plan_item|
      sum + plan_item.human_units
    end
  end

  def units on: Time.zone.today
    plan_items_on(on).to_a.sum &:human_units
  end
end
