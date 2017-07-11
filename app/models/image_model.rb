class ImageModel < ApplicationRecord
  include Auditable
  include ImageModels::Geometry
  include ImageModels::ImageAttributes
  include ImageModels::Validation
  include ParameterSelector

  delegate :organization_id, to: :imageable, allow_nil: true

  mount_uploader :image, ImageUploader, mount_on: :image_file_name

  belongs_to :imageable, polymorphic: true, optional: true

  def identifier
    image_file_name
  end
end
