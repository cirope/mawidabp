module ControlObjectiveItems::History
  extend ActiveSupport::Concern

  def change_history attr
    versions.each_with_object([]) do |version, result|
      coi = version.reify has_one: false

      if field_changed? coi, attr
        date    = I18n.l version.created_at, format: :long
        user    = User.find_by id: version.whodunnit
        action  = I18n.t "control_objective_items.history.actions.#{version.event}"

        history = {
          date:   date.strip,
          user:   user.informal_name,
          action: action,
          change: coi.send(attr)
        }

        result << history
      end
    end
  end

  private

    def field_changed? coi, attr
      coi &&
        coi.send(attr).present? &&
        coi.send(attr) != send(attr)
    end
end
