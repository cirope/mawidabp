# frozen_string_literal: true

class AuxiliarBusinessUnit < ApplicationRecord
  belongs_to :plan_item
  belongs_to :business_unit

  after_destroy :remove_all_scored_business_unit

  private

    def remove_all_scored_business_unit
      ControlObjectiveItem.joins(:review)
                          .where('scored_business_unit_id = ? AND plan_item_id = ?', business_unit_id, plan_item_id)
                          .each do |co_item|
                            co_item.update(scored_business_unit_id: nil)
                          end
    end
end
