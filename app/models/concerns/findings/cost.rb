module Findings::Cost
  extend ActiveSupport::Concern

  included do
    has_many :costs, as: :item, dependent: :destroy
    accepts_nested_attributes_for :costs, allow_destroy: false, reject_if: ->(attributes) {
      attributes['raw_cost'].blank? && attributes['description'].blank?
    }
  end

  def cost
    costs.reject(&:new_record?).sum &:cost
  end
end
