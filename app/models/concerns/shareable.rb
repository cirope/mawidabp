module Shareable
  extend ActiveSupport::Concern

  included do
    scope :on_current_organization, -> {
      where shared: false, organization_id: Organization.current_id
    }
    scope :shared_on_current_group, -> {
      where shared: true, group_id: Group.current_id
    }
    scope :list, -> {
      on_current_organization.or shared_on_current_group
    }
    scope :not_shared, -> { where shared: false }
  end
end
