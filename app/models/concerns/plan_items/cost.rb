module PlanItems::Cost
  extend ActiveSupport::Concern

  def cost
    resource_utilizations.to_a.sum &:cost
  end

  def human_cost
    human_resource_utilizations.sum &:cost
  end

  def material_cost
    material_resource_utilizations.sum &:cost
  end
end
