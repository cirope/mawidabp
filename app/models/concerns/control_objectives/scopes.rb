module ControlObjectives::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      includes(:best_practice).
        where(best_practices: { organization_id: Organization.current_id }).
        references :best_practices
    }
  end
end
