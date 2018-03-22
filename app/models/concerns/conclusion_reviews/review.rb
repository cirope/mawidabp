module ConclusionReviews::Review
  extend ActiveSupport::Concern

  included do
    belongs_to :review

    accepts_nested_attributes_for :review
  end
end
