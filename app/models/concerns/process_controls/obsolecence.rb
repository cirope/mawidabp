module ProcessControls::Obsolecence
  extend ActiveSupport::Concern

  included do
    before_save :cascade_obsolescence
  end

  module ClassMethods
    def hide_process_control_obsolete
      setting = Current.organization.settings.find_by name: 'hide_best_practices_obsolete'

      if setting.value != DEFAULT_SETTINGS[:hide_best_practices_obsolete][:value]
        where(process_controls: { obsolete: false })
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
