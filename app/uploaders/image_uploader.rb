class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file
  process convert: 'png'

  def store_dir
    id = ('%08d' % model.id).scan(/\d{4}/).join('/')
    organization_id = (
      '%08d' % (model.organization_id || Organization.current_id || 0)
    ).scan(/\d{4}/).join('/')

    "private/#{organization_id}/#{model.class.to_s.underscore.pluralize}/#{id}"
  end

  version :medium do
    process resize_to_fit: [600, 600]
    process convert: 'png'
  end

  version :small do
    process resize_to_fit: [300, 300]
    process convert: 'png'
  end

  version :thumb do
    process resize_to_fit: [300, 75]
    process convert: 'png'
  end

  version :pdf_thumb do
    process resize_to_fit: [200, 40]
    process convert: 'png'
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
