module Users::BusinessUnitTypes
  extend ActiveSupport::Concern

  included do
    has_many :business_unit_type_users, dependent: :destroy
    has_many :business_unit_types, through: :business_unit_type_users

    accepts_nested_attributes_for :business_unit_type_users, allow_destroy: true,
      reject_if: ->(attributes) { attributes['business_unit_type_id'].blank? }
  end
end
