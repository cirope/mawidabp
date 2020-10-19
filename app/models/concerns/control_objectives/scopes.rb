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

    def hide_control_objectives_obsolete
      setting = Current.organization.settings.find_by name: 'hide_best_practices_obsolete'

      if setting.value != DEFAULT_SETTINGS[:hide_best_practices_obsolete][:value]
        where(obsolete: false )
      else
        all
      end
    end
  end
end
