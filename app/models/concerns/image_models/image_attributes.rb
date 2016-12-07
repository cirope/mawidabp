module ImageModels::ImageAttributes
  extend ActiveSupport::Concern

  included do
    before_save :update_image_attributes
  end

  def update_image_attributes
    if image.present? && image_file_name_changed?
      self.image_content_type = image.file.content_type
      self.image_file_size = image.file.size
    end
  end
end
