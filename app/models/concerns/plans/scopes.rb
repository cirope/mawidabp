module Plans::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  def business_units_enabled
    rows = Current.user.business_unit_type_ids

    if rows.any?
      business_units.where(
        business_unit_type_id: rows
      )
    else
      business_units
    end
  end
end
