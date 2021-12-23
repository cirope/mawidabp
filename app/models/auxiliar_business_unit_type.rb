# frozen_string_literal: true

class AuxiliarBusinessUnitType < ApplicationRecord
  include AuxiliarBusinessUnitTypes::Validations

  belongs_to :plan_item
  belongs_to :business_unit_type
end
