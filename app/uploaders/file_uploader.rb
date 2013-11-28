class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    id = ('%08d' % model.id).scan(/\d{4}/).join('/')
    organization_id = (
      '%08d' % (Organization.current_id || 0)
    ).scan(/\d{4}/).join('/')

    "private/#{organization_id}/#{model.class.to_s.underscore.pluralize}/#{id}"
  end
end
