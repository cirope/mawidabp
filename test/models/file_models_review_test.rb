require 'test_helper'

class FileModelsReviewTest < ActiveSupport::TestCase
  setup do
    @file_models_review = file_models_reviews :one
  end

  test 'blank attributes' do
    @file_models_review.attr = ''

    assert @file_models_review.invalid?
    assert_error @file_models_review, :attr, :blank
  end

  test 'unique attributes' do
    file_models_review = @file_models_review.dup

    assert file_models_review.invalid?
    assert_error file_models_review, :attr, :taken
  end
end
