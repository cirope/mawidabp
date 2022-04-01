class FileModelMemo < ApplicationRecord
  include Auditable
  include FileModelMemos::Validations

  belongs_to :file_model
  belongs_to :memo

  accepts_nested_attributes_for :file_model, allow_destroy: true,
                                             reject_if: :all_blank
end
