module Questionnaires::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Organization.current_id) }
    scope :by_pollable_type, ->(type) { where(pollable_type: type) }
    scope :pollable, -> { where.not(pollable_type: nil) }
    scope :by_organization, ->(org_id, id) {
      unscoped.where(id: id, organization_id: org_id)
    }
  end
end
