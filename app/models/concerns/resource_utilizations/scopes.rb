module ResourceUtilizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :human,    -> { where resource_type: 'User' }
    scope :material, -> { where resource_type: 'Resource' }
  end

  module ClassMethods
    def planned_on reviews
      joins(:planned_review).where reviews: { id: reviews.map(&:id) }
    end

    def executed_on reviews
      joins(:review).where reviews: { id: reviews.map(&:id) }
    end
  end
end
