module Questionnaires::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Organization.current_id) }
    scope :by_pollable_type, ->(type) { where(pollable_type: type) }
    scope :pollable, -> { where('pollable_type IS NOT NULL') }
    scope :by_organization, ->(org_id, id) {
      unscoped.where('id = :id AND organization_id = :org_id', org_id: org_id, id: id)
    }
  end
end
