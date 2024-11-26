module WorkPapers::History
  extend ActiveSupport::Concern

  def change_history
    versions.each_with_object([]) do |version, result|
      date    = I18n.l version.created_at, format: :long
      user    = User.find_by id: version.whodunnit
      action  = I18n.t "work_papers.history.actions.#{version.event}"
      changes = version_changes(version).join ', '

      history = "(#{date}) #{user.to_s} #{action} #{changes}"

      result << history
    end
  end

  private

    def version_changes version
      version.object_changes.each_with_object([]) do |(attr, changes), result|
        changes = case attr
                  when 'code', 'name', 'description', 'number_of_pages'
                    "#{WorkPaper.human_attribute_name(attr)}: #{changes.last}"
                  when 'status'
                    status = I18n.t "work_papers.statuses.#{changes.last}"

                    "#{WorkPaper.human_attribute_name(attr)}: #{status}"
                  when 'file_model_id'
                    new_file = I18n.t "work_papers.history.new_file"

                    "#{WorkPaper.human_attribute_name('file_model')}: #{new_file}"
                  end

        result << changes if changes.present?
      end
    end
end
