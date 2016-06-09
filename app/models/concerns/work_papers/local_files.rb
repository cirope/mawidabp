module WorkPapers::LocalFiles
  extend ActiveSupport::Concern

  FILE_REGEX = /local:\/\/((?:[\w-]+\/?)+\.\w+)/

  included do
    before_save :check_for_local_file
  end

  private

    def check_for_local_file
      if match = description.to_s.match(FILE_REGEX)
        relative_path = match.captures.first
        path          = Pathname.new("#{base_path}/#{relative_path}").expand_path

        if path.to_s.starts_with?(base_path) && path.exist? && path.readable?
          build_file_model unless file_model

          path.open { |file| file_model.file = file }

          self.description = description.sub FILE_REGEX, '' if file_model.valid?
        end
      end
    end

    def base_path
      setting = organization.settings.find_by name: 'exchange_directory_path'

      setting ? setting.value : DEFAULT_SETTINGS[:exchange_directory_path][:value]
    end
end
