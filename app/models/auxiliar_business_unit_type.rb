# frozen_string_literal: true

class AuxiliarBusinessUnitType < ApplicationRecord
  belongs_to :plan_item
  belongs_to :business_unit_type

  has_one :review, through: :plan_item
  has_many :control_objective_items, through: :review

  after_destroy :remove_all_scored_business_unit_type

  private

    def remove_all_scored_business_unit_type
      control_objective_items.update_all scored_business_unit_type_id: nil
    end
end
