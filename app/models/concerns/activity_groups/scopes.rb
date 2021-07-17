module ActivityGroups::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list_group, -> { where organization_id: Current.organization.group.organizations&.ids }
    scope :list, -> { where organization_id: Current.organization&.id }
  end
end
