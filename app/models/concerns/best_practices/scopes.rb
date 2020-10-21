module BestPractices::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order obsolete: :asc, name: :asc }
  end

  module ClassMethods
    def visible
      setting = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'

      hide_obsolete_best_practices = DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value]

      if (setting ? setting.value : hide_obsolete_best_practices) == '0'
        all
      else
        where(obsolete: false)
      end
    end
  end
end
