module BusinessUnitTypes::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Organization.current_id).
        order(external: :asc, name: :asc)
    }
    scope :internal_audit, -> { where external: false }
    scope :external_audit, -> { where external: true }
  end
end
