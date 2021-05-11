class BusinessUnitTypeReview < ApplicationRecord
  include Auditable
  include BusinessUnitTypeReviews::Validations

  belongs_to :business_unit_type
  belongs_to :review
end
