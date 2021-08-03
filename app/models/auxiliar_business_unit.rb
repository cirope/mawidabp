# frozen_string_literal: true

class AuxiliarBusinessUnit < ApplicationRecord
  belongs_to :plan_item
  belongs_to :business_unit

  has_one :review, through: :plan_item
  has_many :control_objective_items, through: :review

  after_destroy :remove_all_scored_business_unit

  private

    def remove_all_scored_business_unit
      control_objective_items.each do |co_i|
        co_i.update(scored_business_unit_id: nil)
      end
    end
end
