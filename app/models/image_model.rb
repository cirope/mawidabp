class ImageModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  mount_uploader :image, ImageUploader, :mount_on => :image_file_name

  # Callbacks
  before_save :update_image_attributes

  # Restricciones
  validates :image_file_name, :image_content_type, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true

  def image_size(style_name = :original)
    image_geometry = image_geometry(style_name)

    "#{image_geometry[:width]}x#{image_geometry[:height]}"
  end

  def image_geometry(style_name = :original)
    @_image_dimensions ||= {}
    
    if File.exists?(self.image.send(style_name).path)
      ::Magick::Image::read(self.image.send(style_name).path).first.tap do |img|
        @_image_dimensions[style_name] ||= {
          :width => img.columns, :height => img.rows
        }
      end 
    end

    @_image_dimensions[style_name] || {}
  end

  def update_image_attributes
    if image.present? && image_file_name_changed?
      self.image_content_type = image.file.content_type
      self.image_file_size = image.file.size
    end
  end
end
