require 'test_helper'

class ConclusionReviewsHelperTest < ActionView::TestCase
  fixtures :conclusion_reviews

  setup do
    @conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_current_draft_review).id
    )

    set_organization
  end

  test 'Should return score' do
    expected = if USE_SCOPE_CYCLE && @conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      @conclusion_review.review.score_text
    end

    assert_equal score_text_for(@conclusion_review), expected
  end

  test 'Should return proper score when the control objective item is excluded from score' do
    @conclusion_review = conclusion_reviews(
      :conclusion_approved_with_conclusion_draft_review
    )

    control_objective_item = @conclusion_review.control_objective_items.take
    control_objective_item.exclude_from_score = true
    control_objective_item.save

    expected = if USE_SCOPE_CYCLE && @conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      @conclusion_review.review.score_text
    end

    assert_equal score_text_for(@conclusion_review), expected
  end
end
