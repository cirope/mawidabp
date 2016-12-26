module PlanItems::ResourceUtilizations
  extend ActiveSupport::Concern

  included do
    has_many :resource_utilizations, as: :resource_consumer, dependent: :destroy

    accepts_nested_attributes_for :resource_utilizations, allow_destroy: true
  end

  def material_resource_utilizations
    resource_utilizations.select &:material?
  end

  def human_resource_utilizations
    resource_utilizations.select &:human?
  end
end
