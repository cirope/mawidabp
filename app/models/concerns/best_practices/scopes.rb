module BestPractices::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order obsolete: :asc, name: :asc }
  end

  module ClassMethods
    def visible
      setting = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'

      if setting.value != '0'
        where(obsolete: false)
      else
        all
      end
    end
  end
end
