module ActivityGroups::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization.group.organizations.ids }
  end
end
