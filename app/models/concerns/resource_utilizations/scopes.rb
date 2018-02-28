module ResourceUtilizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :human,    -> { where resource_type: 'User' }
    scope :material, -> { where resource_type: 'Resource' }
  end

  module ClassMethods
    def planned_on reviews
      joins(:planed_review).where reviews: { id: reviews.map(&:id) }
    end

    def executed_on reviews
      joins(:review).where reviews: { id: reviews.map(&:id) }
    end

    def items_planned_on plan_items
      joins(:plan_item).where plan_items: { id: plan_items.map(&:id) }
    end

    def items_executed_on plan_items
      joins(:review).where reviews: { plan_item_id: plan_items.map(&:id) }
    end
  end
end
