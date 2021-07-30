# frozen_string_literal: true

class AuxiliarBusinessUnit < ApplicationRecord
  belongs_to :plan_item
  belongs_to :business_unit
end
