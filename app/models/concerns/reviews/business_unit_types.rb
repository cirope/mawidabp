module Reviews::BusinessUnitTypes
  extend ActiveSupport::Concern

  included do
    has_many :business_unit_type_reviews, dependent: :destroy
    has_many :business_unit_types, through: :business_unit_type_reviews

    accepts_nested_attributes_for :business_unit_type_reviews, allow_destroy: true,
      reject_if: :all_blank
  end
end
