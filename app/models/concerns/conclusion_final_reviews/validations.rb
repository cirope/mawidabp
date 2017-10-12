module ConclusionFinalReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :close_date, :conclusion, presence: true
    validates :review_id, uniqueness: true, allow_blank: true, allow_nil: true
    validates :close_date, timeliness: { type: :date, on_or_after: :issue_date },
      allow_nil: true, allow_blank: true, on: :create
    validate :review_must_be_approved
    validate :review_must_have_draft
  end

  private

    def review_must_be_approved
      if has_draft_review? && !review.conclusion_draft_review.approved?
        errors.add :review_id, :invalid
      end
    end

    def review_must_have_draft
      errors.add :review_id, :without_draft unless has_draft_review?
    end

    def has_draft_review?
      review && review.conclusion_draft_review
    end
end
