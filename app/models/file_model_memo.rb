class FileModelMemo < ApplicationRecord
  include Auditable
  include FileModelMemos::Validations

  belongs_to :file_model, dependent: :destroy
  belongs_to :memo

  accepts_nested_attributes_for :file_model, allow_destroy: true,
                                             reject_if: :all_blank
end
