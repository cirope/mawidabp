module ControlObjectiveItems::History
  extend ActiveSupport::Concern

  def change_history
    grouped_versions.each_with_object([]) do |version, result|
      date    = I18n.l version.created_at, format: :long
      user    = User.find_by id: version.whodunnit
      action  = I18n.t "control_objective_items.history.actions.#{version.event}"
      changes = version_changes version

      history = {
        date:    date.strip,
        user:    user.informal_name,
        action:  action,
        changes: changes
      }

      result << history
    end
  end

  private

    def grouped_versions
      finished_versions        = relevant_versions.select { |v| v.object_changes.key?('finished') }.last(5)
      auditor_comment_versions = relevant_versions.select { |v| v.object_changes.key?('auditor_comment') }.last(5)

      (finished_versions + auditor_comment_versions).sort_by &:created_at
    end

    def relevant_versions
      versions.select do |version|
        next unless version.object_changes

        (version.object_changes.keys & relevant_attributes).any?
      end
    end

    def relevant_attributes
      %w[finished auditor_comment]
    end

    def version_changes version
      version.object_changes.each_with_object([]) do |(attr, values), result|
        value = case attr
                when 'auditor_comment' then I18n.t 'control_objective_items.history.default_field_modified'
                when 'finished'        then I18n.t values.last ? 'label.yes' : 'label.no'
                end

        result << { ControlObjectiveItem.human_attribute_name(attr) => value } if value
      end
    end
end
