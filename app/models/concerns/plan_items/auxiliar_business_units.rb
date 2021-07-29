# frozen_string_literal: true

module PlanItems::AuxiliarBusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :business_unit_in_plan_items, dependent: :destroy
    has_many :auxiliar_business_units, through: :business_unit_in_plan_items

    accepts_nested_attributes_for :auxiliar_business_units, allow_destroy: true
  end
end
