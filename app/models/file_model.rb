class FileModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  has_attached_file :file,
    :path => ':rails_root/private/:organization_id/:class/:id/:basename.:extension',
    :url => '/private/:organization_id/:class/:id/:basename.:extension'
  
  # Atributos no persistentes
  attr_accessor :delete_file
  
  # Callbacks
  before_save :destroy_file?

  # Restricciones
  validates_attachment_size :file, :less_than => 20.megabytes,
    :message => lambda {
      I18n.t('activerecord.errors.messages.less_than', :count => 20.megabytes)
    }
  validates :file_file_name, :file_content_type, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true
  validates_each :file_file_name do |record, attr, value|
    record.errors.add attr, :without_extension if File.extname(value.to_s).blank?
  end
  
  def delete_file?
    self.delete_file == '1' || self.delete_file == true
  end
  
  def changed?
    self.delete_file? || super
  end
  
  def destroy_file?
    self.file.clear if self.delete_file?
  end
end