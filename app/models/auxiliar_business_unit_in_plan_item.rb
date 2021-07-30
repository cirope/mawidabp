# frozen_string_literal: true

class AuxiliarBusinessUnitInPlanItem < ApplicationRecord
  belongs_to :plan_item
  belongs_to :business_unit
end
