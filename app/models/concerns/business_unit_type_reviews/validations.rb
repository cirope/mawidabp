module BusinessUnitTypeReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :business_unit_type_id, uniqueness: { scope: :review_id }
  end
end
