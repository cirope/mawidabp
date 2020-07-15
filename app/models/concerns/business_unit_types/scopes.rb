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
    def business_unit_type_enabled
      but = BusinessUnitType.list
      rows = Current.user.business_unit_type_ids

      if rows.count > 0
        but = but.where(id: rows)
      else
        but = but + [nil]
      end

      but
    end
  end
end
