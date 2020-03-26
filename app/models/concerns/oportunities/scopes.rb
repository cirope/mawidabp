module Oportunities::Scopes
  extend ActiveSupport::Concern

  included do
    scope :all_for_report, -> {
      where(
        state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values,
        final: true
      ).order(state: :asc)
    }

    scope :final_without_review, -> {
      where(final: true).where.not(
        ConclusionReview.table_name => { review_id: nil }
      )
    }
    scope :not_final_with_review, -> {
      where(final: false, ConclusionReview.table_name => { review_id: nil })
    }

    scope :with_or_without_review, -> { not_final_with_review.or(final_without_review) }
  end
end
