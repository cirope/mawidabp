module ConclusionReviewsHelper
  def score_text_for conclusion_review
    if USE_SCOPE_CYCLE && conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      conclusion_review.review.score_text
    end
  end

  def score_alt_text_for conclusion_review
    if conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      conclusion_review.review.score_alt_text
    end
  end
end
