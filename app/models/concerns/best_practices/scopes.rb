module BestPractices::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order obsolete: :asc, name: :asc }
  end

  module ClassMethods
    def hide_best_practices_obsolete
      setting = Current.organization.settings.find_by name: 'hide_best_practices_obsolete'

      if setting.value != DEFAULT_SETTINGS[:hide_best_practices_obsolete][:value]
        where(obsolete: false)
      else
        all
      end
    end
  end
end
