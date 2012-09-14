# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  storage :file
  process :convert => 'png'

  def store_dir
    id = ('%08d' % model.id).scan(/\d{4}/).join('/')
    organization_id = (
      '%08d' % (GlobalModelConfig.current_organization_id || 0)
    ).scan(/\d{4}/).join('/')
  
    "private/#{organization_id}/#{model.class.to_s.underscore.pluralize}/#{id}"
  end

  version :thumb do
    process :resize_to_fit => [300, 75]
    process :convert => 'png'
  end

  version :pdf_thumb do
    process :resize_to_fit => [200, 40]
    process :convert => 'png'
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    "#{super.chomp(File.extname(super))}.png"
  end
end
