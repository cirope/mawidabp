module Plans::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  def allowed_business_units
    rows = Current.user.business_units

    if rows.any?
      rows
    else
      business_units
    end
  end
end
