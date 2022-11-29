class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file
  after :remove, :delete_empty_upstream_dirs

  def store_dir
    id = ('%08d' % model.id).scan(/\d{4}/).join('/')

    organization_id = (
      '%08d' % (model.organization_id || Current.organization&.id || 0)
    ).scan(/\d{4}/).join('/')

    File.join RELATIVE_PRIVATE_PATH, organization_id, model.class.to_s.underscore.pluralize, id
  end

  version :medium do
    process resize_to_fit: [600, 600]
    process convert: 'png'

    def full_filename for_file
      full_filename_with_extension super(for_file), 'png'
    end
  end

  version :small do
    process resize_to_fit: [300, 300]
    process convert: 'png'

    def full_filename for_file
      full_filename_with_extension super(for_file), 'png'
    end
  end

  version :thumb do
    process resize_to_fit: [300, 75]
    process convert: 'png'

    def full_filename for_file
      full_filename_with_extension super(for_file), 'png'
    end
  end

  version :pdf_thumb do
    process resize_to_fit: [200, 40]
    process convert: 'png'

    def full_filename for_file
      full_filename_with_extension super(for_file), 'png'
    end
  end

  def extension_allowlist
    %w(jpg jpeg gif png)
  end

  private

    def full_filename_with_extension filename, new_extension
      extension = File.extname filename

      "#{filename.chomp extension}.#{new_extension}"
    end

    def delete_empty_upstream_dirs
      Dir.delete(store_dir) if Dir.exist?(store_dir) && Dir.empty?(store_dir)

      parent_dir = File.dirname(store_dir)

      Dir.delete(parent_dir) if Dir.exist?(parent_dir) && Dir.empty?(parent_dir)
    end
end
