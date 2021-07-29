# frozen_string_literal: true

module PlanItems::AuxiliarBusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :auxiliar_business_unit, dependent: :destroy
    has_many :auxiliar_business_units, through: :auxiliar_business_unit

    accepts_nested_attributes_for :auxiliar_business_unit, allow_destroy: true
  end
end
