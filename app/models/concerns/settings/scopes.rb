module Settings::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Current.organization_id).order(name: :asc) }
  end
end
