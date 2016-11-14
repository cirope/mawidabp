module FileModels::FileAttributes
  extend ActiveSupport::Concern

  included do
    before_validation :update_file_attributes
  end

  private

    def update_file_attributes
      if file.present? && file_file_name_changed?
        self.file_file_name    = file.file.filename
        self.file_content_type = file.file.content_type
        self.file_file_size    = file.file.size
        self.file_updated_at   = Time.zone.now
      end
    end
end
