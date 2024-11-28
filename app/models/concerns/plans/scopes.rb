module Plans::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  def allowed_business_units
    bu = Current.user.business_units

    bu.any? ? bu : business_units
  end
end
