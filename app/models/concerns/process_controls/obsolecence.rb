module ProcessControls::Obsolecence
  extend ActiveSupport::Concern

  included do
    before_save :cascade_obsolescence
  end

  private

    def cascade_obsolescence
      if obsolete && obsolete_changed?
        control_objectives.each { |co| co.obsolete = true }
      end
    end
end
