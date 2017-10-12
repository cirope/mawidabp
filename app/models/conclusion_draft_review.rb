class ConclusionDraftReview < ConclusionReview
  include ConclusionDraftReviews::Approval

  COLUMNS_FOR_SEARCH = GENERIC_COLUMNS_FOR_SEARCH

  validates :review_id, uniqueness: true, allow_blank: true, allow_nil: true

  def can_be_destroyed?
    !review.has_final_review?
  end
end
