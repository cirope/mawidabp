module Plans::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  def business_units_enabled plan
    rows = Current.user.business_unit_type_ids

    if rows.count > 0
      plan.business_units.where(
        business_unit_type_id: rows
      )
    else
      plan.business_units
    end
  end
end
