require 'test_helper'
include SimpleForm::ActionViewExtensions::FormHelper

class ConclusionReviewsHelperTest < ActionView::TestCase
  fixtures :conclusion_reviews

  setup do
    @conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_current_draft_review).id
    )

    set_organization

    @form = ActionView::Helpers::FormBuilder.new :conclusion_draft_review, @conclusion_review, self, {}
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

  test 'Should return an array for conclusion_review_options_collection' do
    result = conclusion_review_options_collection
    assert_kind_of Array, result
    CONCLUSION_REVIEW_OPTIONS.each do |label, key|
      assert_includes result, [label, key]
    end
  end

  test 'Should generate input option with proper attributes' do
    option = CONCLUSION_REVIEW_OPTIONS.first

    simple_form_for(@conclusion_review) do |form|
      html = conclusion_review_input_option form, @conclusion_review, option

      assert_match /input/, html
      assert_match /#{option.last}/, html
      assert_match /type="checkbox"/, html
      assert_match /checked/, html if @conclusion_review.option_value option.last
    end
  end

  test 'Should generate readonly input option when specified' do
    option = CONCLUSION_REVIEW_OPTIONS.first

    simple_form_for(@conclusion_review) do |form|
      html = conclusion_review_input_option form, @conclusion_review, option, readonly: true

      assert_match /readonly/, html
    end
  end

  test 'Should generate input option without readonly by default' do
    option = CONCLUSION_REVIEW_OPTIONS.first

    simple_form_for(@conclusion_review) do |form|
      html = conclusion_review_input_option form, @conclusion_review, option

      refute_match /readonly/, html
    end
  end
end
