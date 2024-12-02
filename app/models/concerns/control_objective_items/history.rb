module ControlObjectiveItems::History
  extend ActiveSupport::Concern

  def change_history
    versions.each_with_object([]) do |version, result|
      coi = version.reify has_one: false

      if coi&.auditor_comment && coi.auditor_comment != auditor_comment
        date    = I18n.l version.created_at, format: :long
        user    = User.find_by id: version.whodunnit
        action  = I18n.t "control_objective_items.history.actions.#{version.event}"

        history = {
          date:   date.strip,
          user:   user.informal_name,
          action: action,
          change: coi.auditor_comment
        }

        result << history
      end
    end
  end
end
