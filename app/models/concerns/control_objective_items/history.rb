module ControlObjectiveItems::History
  extend ActiveSupport::Concern

  def change_history attribute
    versions.each_with_object([]) do |version, result|
      coi = version.reify has_one: false

      if field_changed? coi, attribute
        date    = I18n.l version.created_at, format: :long
        user    = User.find_by id: version.whodunnit
        action  = I18n.t "control_objective_items.history.actions.#{version.event}"

        history = {
          date:   date.strip,
          user:   user.informal_name,
          action: action,
          change: coi.send(attribute)
        }

        result << history
      end
    end
  end

  private

    def field_changed? coi, attribute
      coi &&
        coi.send(attribute).present? &&
        coi.send(attribute) != send(attribute)
    end
end
