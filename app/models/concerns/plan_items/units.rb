module PlanItems::Units
  extend ActiveSupport::Concern

  def units
    resource_utilizations.map(&:units).compact.sum
  end

  def human_units
    human_resource_utilizations.map(&:units).compact.sum
  end

  def material_units
    material_resource_utilizations.map(&:units).compact.sum
  end
end
