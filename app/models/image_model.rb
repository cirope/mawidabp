class ImageModel < ActiveRecord::Base
  include Auditable
  include ImageModels::Geometry
  include ImageModels::ImageAttributes
  include ImageModels::Validation
  include ParameterSelector

  mount_uploader :image, ImageUploader, mount_on: :image_file_name

  attr_accessor :organization_id

  def identifier
    image_file_name
  end
end
