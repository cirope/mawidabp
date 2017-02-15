module ResourceUtilizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :human,    -> { where resource_type: 'User' }
    scope :material, -> { where resource_type: 'Resource' }
  end

  module ClassMethods
    def planed_on reviews
      joins(:planed_review).where reviews: { id: reviews.map(&:id) }
    end

    def executed_on reviews
      joins(:review).where reviews: { id: reviews.map(&:id) }
    end
  end
end
