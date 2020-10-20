module ProcessControls::Obsolecence
  extend ActiveSupport::Concern

  included do
    before_save :cascade_obsolescence
  end

  module ClassMethods
    def visible
      setting = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'

      if setting.value != '0'
        where(obsolete: false )
      else
        all
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
