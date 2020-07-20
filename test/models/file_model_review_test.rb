require 'test_helper'

class FileModelsReviewTest < ActiveSupport::TestCase
  setup do
    @file_model_review = file_model_reviews :file_model_review_relation
  end

  test 'blank attributes' do
    @file_model_review.file_model_id = ''
    @file_model_review.review_id = ''

    assert @file_model_review.invalid?
    assert_error @file_model_review, :file_model, :blank
    assert_error @file_model_review, :review, :blank
  end

  test 'unique attributes' do
    file_model_review = @file_model_review.dup

    assert file_model_review.invalid?
    assert_error file_model_review, :file_model_id, :taken
  end
end
