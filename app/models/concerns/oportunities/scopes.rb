module Oportunities::Scopes
  extend ActiveSupport::Concern

  included do
    scope :all_for_report, -> {
      where(
        state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values,
        final: true
      ).order state: :asc
    }

    scope :final_with_conclusion_review, -> {
      where(final: true).where.not ConclusionReview.table_name => { review_id: nil }
    }
    scope :not_final_without_conclusion_review, -> {
      where final: false, ConclusionReview.table_name => { review_id: nil }
    }
    scope :execution_list, -> {
      not_final_without_conclusion_review.or final_with_conclusion_review
    }
  end
end
