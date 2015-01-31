module BestPractices::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Organization.current_id).order(name: :asc)
    }
  end
end
