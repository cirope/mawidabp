module ActivityGroups::Scopes
  extend ActiveSupport::Concern

  included do
    scope :group_list, -> { where organization_id: Current.organization&.group.organizations.ids }
    scope :list,       -> { where organization_id: Current.organization&.id }
  end
end
