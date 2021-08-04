# frozen_string_literal: true

module PlanItems::AuxiliarBusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :auxiliar_business_units, dependent: :destroy

    accepts_nested_attributes_for :auxiliar_business_units, allow_destroy: true
  end
end
