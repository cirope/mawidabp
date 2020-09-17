class BusinessUnitTypeUser < ApplicationRecord
  include Auditable
  include BusinessUnitTypeUsers::Validations

  belongs_to :business_unit_type
  belongs_to :user
end
