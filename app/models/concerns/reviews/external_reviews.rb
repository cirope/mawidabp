module Reviews::ExternalReviews
  extend ActiveSupport::Concern

  included do
    has_many :external_reviews, dependent: :destroy

    accepts_nested_attributes_for :external_reviews, allow_destroy: true
  end
end
