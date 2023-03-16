module AuxiliarBusinessUnitTypes::Validations
  extend ActiveSupport::Concern

  included do
    validates :business_unit_type, uniqueness: { scope: :plan_item }
  end
end
