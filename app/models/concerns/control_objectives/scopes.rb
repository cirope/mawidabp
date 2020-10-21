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

    def visible
      setting = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'

      hide_obsolete_best_practices = DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value]

      if (setting ? setting.value : hide_obsolete_best_practices) == '0'
        all
      else
        where(obsolete: false )
      end
    end
  end
end
