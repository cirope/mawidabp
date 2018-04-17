require 'test_helper'

class BestPracticeCommentTest < ActiveSupport::TestCase
  setup do
    @best_practice_comment = best_practice_comments :bcra_A4609_on_current
  end

  test 'blank attributes' do
    @best_practice_comment.auditor_comment = '   '
    @best_practice_comment.best_practice = nil

    assert @best_practice_comment.invalid?
    assert_error @best_practice_comment, :auditor_comment, :blank
    assert_error @best_practice_comment, :best_practice, :blank
  end
end
