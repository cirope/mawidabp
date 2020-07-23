module Workflows::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Current.organization&.id) }
  end

  module ClassMethods
    def allowed_by_business_units
      bu = Current.user.business_units

      if bu.any?
        where reviews: { plan_item_id: PlanItem.where(business_unit_id: bu.ids)}
      else
        all
      end
    end

  end
end
