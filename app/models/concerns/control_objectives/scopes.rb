module ControlObjectives::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      includes(:best_practice).
        where(best_practices: { organization_id: Current.organization&.id }).
        references :best_practices
    }
  end

  module ClassMethods
    def default_order
      reorder(
        POSTGRESQL_ADAPTER ? { name: :asc } : { created_at: :asc }
      )
    end
  end
end
