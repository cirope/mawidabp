module Users::Group
  extend ActiveSupport::Concern

  included do
    has_one :organization_role
    has_one :organization, through: :organization_role
    has_one :group, through: :organization
  end
end
