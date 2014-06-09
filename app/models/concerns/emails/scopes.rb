module Emails::Scopes
  extend ActiveSupport::Concern

  included do
    default_scope { order 'created_at DESC' }
    scope :list, -> { where organization_id: Organization.current_id }
  end
end
