class ImageModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  has_attached_file :image,
    :path => ':rails_root/private/:organization_id/:class/:id/:basename_:style.:extension',
    :url => '/private/:organization_id/:class/:id/:basename_:style.:extension',
    :styles => { :thumb => ['300x75>', :png], :pdf_thumb => ['200x40>', :png] }

  # Restricciones
  validates_attachment_content_type :image, :content_type => /\Aimage/i,
    :message => I18n.t(:invalid, :scope => [:activerecord, :errors, :models, :image_model, :attributes, :image_content_type])
  validates_attachment_size :image, :less_than => 20.megabytes,
    :message => I18n.t(:'activerecord.errors.messages.less_than', :count => 20.megabytes)
  validates :image_file_name, :image_content_type, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true

  def image_size(style_name = :original)
    image_geometry = image_geometry(style_name)

    "#{image_geometry[:width]}x#{image_geometry[:height]}"
  end

  def image_geometry(style_name = :original)
    @_image_dimensions ||= {}
    
    if File.exists?(self.image.path(style_name))
      @_image_dimensions[style_name] ||= Paperclip::Geometry.from_file(
        File.new(self.image.path(style_name), 'r'))
    end

    dimensions = @_image_dimensions[style_name]

    {:width => dimensions.try(:width), :height => dimensions.try(:height)}
  end
end