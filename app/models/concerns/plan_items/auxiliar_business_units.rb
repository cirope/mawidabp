# frozen_string_literal: true

module PlanItems::AuxiliarBusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :auxiliar_business_unit_in_plan_items, dependent: :destroy
    has_many :auxiliar_business_units, through: :auxiliar_business_unit_in_plan_items, source: :business_unit

    accepts_nested_attributes_for :auxiliar_business_unit_in_plan_items, allow_destroy: true
  end
end
