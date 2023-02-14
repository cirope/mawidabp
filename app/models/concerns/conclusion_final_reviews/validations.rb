module ConclusionFinalReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :close_date, :conclusion, presence: true
    validates :review_id, uniqueness: true, allow_blank: true, allow_nil: true
    validates :close_date, timeliness: { type: :date, on_or_after: :issue_date },
      allow_nil: true, allow_blank: true, on: :create
    validate :review_must_be_approved
    validate :review_must_have_draft
    validate :external_review_must_be_earlier, if: :is_nbc?
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

    def is_nbc?
      Current.conclusion_pdf_format == 'nbc'
    end

    def external_review_must_be_earlier
      review.external_reviews.map(&:alternative_review).each do |alt_review|
        alt_issue_date = alt_review.conclusion_final_review.issue_date

        if issue_date && alt_issue_date > issue_date
          errors.add :issue_date, :less_than_alt_issue_date,
            date: alt_issue_date, name: alt_review.identification
        end
      end
    end
end
