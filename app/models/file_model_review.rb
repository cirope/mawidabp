class FileModelReview < ApplicationRecord
  include Auditable

  belongs_to :file_model
  belongs_to :review

  accepts_nested_attributes_for :file_model, :allow_destroy => true,
    reject_if: :all_blank
end
