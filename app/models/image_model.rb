class ImageModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  has_attachment :content_type => :image, :storage => :file_system,
    :max_size => 2.megabytes,
    :path_prefix => "#{PRIVATE_FILES_PREFIX}/#{table_name}",
    :thumbnails => { :thumb => '300x75>', :pdf_thumb => '200x40>' }

  # Restricciones
  validates_as_attachment
  validates_length_of :filename, :content_type, :thumbnail, :maximum => 255,
    :allow_nil => true, :allow_blank => true

  def thumb(suffix)
    self.find_or_initialize_thumbnail suffix
  end

  def base_path
    RAILS_ROOT
  end
end