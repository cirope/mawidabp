module WeaknessTemplates::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Organization.current_id }
  end
end
