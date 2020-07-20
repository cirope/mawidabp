class FileModelReview < ApplicationRecord
  belongs_to :file_model
  belongs_to :review

  accepts_nested_attributes_for :file_model, :allow_destroy => true,
    reject_if: ->(attrs) { ['file', 'file_cache'].all? { |a| attrs[a].blank? } }

end
