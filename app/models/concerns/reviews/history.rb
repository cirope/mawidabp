module Reviews::History
  extend ActiveSupport::Concern

  included do
    before_save :check_for_status_changes
  end

  def change_history
    relevant_versions.each_with_object([]) do |version, result|
      date    = I18n.l version.created_at, format: :long
      user    = User.find_by id: version.whodunnit
      action  = I18n.t "reviews.history.actions.#{version.event}"
      changes = version_changes version

      history = {
        date:    date.strip,
        user:    user.informal_name,
        action:  action,
        changes: changes
      }

      result << history if changes.present?
    end
  end

  private

    def relevant_versions
      versions.select do |version|
        version.object_changes.key?('status')
      end
    end

    def version_changes version
      version.object_changes.each_with_object([]) do |(attr, values), result|
        changes = {}

        if attr == 'status'
          new_status = I18n.t "reviews.statuses.#{values.last}"

          changes[Review.human_attribute_name(attr)] = new_status
        end

        result << changes if changes.present?
      end
    end

    def check_for_status_changes
      self.status_will_change! if new_record?
    end
end
