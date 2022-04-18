class ExternalReview < ApplicationRecord
  include Auditable
  include ExternalReviews::Validations

  belongs_to :review
  belongs_to :alternative_review, class_name: 'Review'
end
