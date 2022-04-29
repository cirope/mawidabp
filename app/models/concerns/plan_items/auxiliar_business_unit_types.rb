# frozen_string_literal: true

module PlanItems::AuxiliarBusinessUnitTypes
  extend ActiveSupport::Concern

  included do
    has_many :auxiliar_business_unit_types, dependent: :destroy

    accepts_nested_attributes_for :auxiliar_business_unit_types, allow_destroy: true, reject_if: :all_blank
  end
end
