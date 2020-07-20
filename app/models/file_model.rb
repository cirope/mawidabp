class FileModel < ApplicationRecord
  include Auditable
  include FileModels::Dirty
  include FileModels::FileAttributes
  include FileModels::Validation
  include ParameterSelector

  mount_uploader :file, FileUploader, mount_on: :file_file_name

  attr_accessor :organization_id

  def identifier
    file.identifier || file_identifier
  end
end
