module BusinessUnitTypeUsers::Validations
  extend ActiveSupport::Concern

  included do
    validates :business_unit_type_id, uniqueness: { scope: :user_id }
  end
end

