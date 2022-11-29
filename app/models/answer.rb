class Answer < ApplicationRecord
  include ActiveStorage::HasOneFile
  include Auditable
  include Answers::Completed
  include Answers::Validations

  belongs_to :question, optional: true
  belongs_to :poll, optional: true
  belongs_to :answer_option, optional: true

  mount_uploader :attached, FileUploader

  delegate :organization_id, to: :poll, allow_nil: true
end
