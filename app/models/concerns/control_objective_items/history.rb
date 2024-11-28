module ControlObjectiveItems::History
  extend ActiveSupport::Concern

  def change_history attr
    result = []

    versions.each_with_object([]) do |version|
      coi = version.reify has_one: false

      if exist_element? coi, attr
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

    result
  end

  private

  def exist_element? coi, attr
    coi &&
      coi.send(attr).present? &&
      coi.send(attr) != send(attr)
  end
end
