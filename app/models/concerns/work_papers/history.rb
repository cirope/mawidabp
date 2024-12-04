module WorkPapers::History
  extend ActiveSupport::Concern

  included do
    before_save :check_for_file_model_changes
  end

  def change_history
    versions.each_with_object([]) do |version, result|
      date    = I18n.l version.created_at, format: :long
      user    = User.find_by id: version.whodunnit
      action  = I18n.t "work_papers.history.actions.#{version.event}"
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

    def version_changes version
      version.object_changes.each_with_object([]) do |(attr, values), result|
        changes = {}

        case attr
        when 'code', 'name', 'description', 'number_of_pages'
          changes["#{WorkPaper.human_attribute_name(attr)}"] = values.last
        when 'status'
          status = I18n.t "work_papers.statuses.#{values.last}"

          changes["#{WorkPaper.human_attribute_name(attr)}"] = status
        when 'file_model_id'
          new_file = I18n.t "work_papers.history.new_file"

          changes["#{WorkPaper.human_attribute_name('file_model')}"] = new_file
        end

        result << changes if changes.present?
      end
    end

    def check_for_file_model_changes
      file_model_id_will_change! if file_model&.changed?
    end
end
