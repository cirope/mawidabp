module BusinessUnitTypes::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Current.organization.id).
        order(external: :asc, name: :asc)
    }
    scope :internal_audit, -> { where external: false }
    scope :external_audit, -> { where external: true }
  end
end
