class FileModel < ApplicationRecord
  include Auditable
  include FileModels::Dirty
  include FileModels::FileAttributes
  include FileModels::Validation
  include ParameterSelector

  mount_uploader :file, FileUploader, mount_on: :file_file_name

    has_many :file_model_reviews
    has_many :reviews, through: :file_model_reviews

  attr_accessor :organization_id

  def identifier
    file.identifier || file_identifier
  end
end
