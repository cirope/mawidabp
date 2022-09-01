module ProcessControls::Obsolecence
  extend ActiveSupport::Concern

  included do
    before_save :cascade_obsolescence
  end

  module ClassMethods
    def visible
      setting                      = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'
      hide_obsolete_best_practices = DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value]

      if (setting ? setting.value : hide_obsolete_best_practices) == '0'
        all
      else
        where(obsolete: false)
      end
    end
  end

  private

    def cascade_obsolescence
      if obsolete && obsolete_changed?
        control_objectives.each { |co| co.obsolete = true }
      end
    end
end
