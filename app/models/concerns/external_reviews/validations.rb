module ExternalReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :review, :alternative_review_id, presence: true
    validates :alternative_review, uniqueness: {
      case_sensitive: false, scope: :review_id
    }
  end
end
