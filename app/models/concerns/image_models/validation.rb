module ImageModels::Validation
  extend ActiveSupport::Concern

  included do
    validates :image_file_name, :image_content_type,
      length: { maximum: 255 }, allow_nil: true, allow_blank: true
  end
end
