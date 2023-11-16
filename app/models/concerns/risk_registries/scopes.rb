module RiskRegistries::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> {
      order name: :asc
    }
    scope :list, -> {
      where organization_id: Current.organization&.id
    }
  end
end
