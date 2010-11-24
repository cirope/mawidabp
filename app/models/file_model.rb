class FileModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  has_attached_file :file,
    :path => ':rails_root/private/:organization_id/:class/:id/:basename.:extension',
    :url => '/private/:organization_id/:class/:id/:basename.:extension'

  # Restricciones
  validates_attachment_size :file, :less_than => 10.megabytes,
    :message => I18n.t(:'activerecord.errors.messages.less_than', :count => 20.megabytes)
  validates_length_of :file_file_name, :file_content_type, :maximum => 255,
    :allow_nil => true, :allow_blank => true
end