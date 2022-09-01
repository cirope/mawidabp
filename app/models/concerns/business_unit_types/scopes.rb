module BusinessUnitTypes::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Current.organization&.id).
        order(external: :asc, name: :asc)
    }
    scope :internal_audit, -> { where external: false }
    scope :external_audit, -> { where external: true }
  end

  module ClassMethods
    def allowed_business_unit_types
      buts = Current.user.business_unit_types.list

      if buts.any?
        buts
      else
        BusinessUnitType.list + [nil]
      end
    end
  end
end
