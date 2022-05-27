module Memos::PlanItem
  extend ActiveSupport::Concern

  included do
    belongs_to :plan_item
    has_one :business_unit, through: :plan_item
    has_one :business_unit_type, through: :business_unit
  end
end
