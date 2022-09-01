module Permalinks::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where organization_id: Current.organization&.id
    }
  end
end
