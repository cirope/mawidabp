require 'test_helper'

class RiskScoreItemTest < ActiveSupport::TestCase
  setup do
    @risk_score_item = risk_score_items :one
  end

  test 'blank attributes' do
    @risk_score_item.attr = ''

    assert @risk_score_item.invalid?
    assert_error @risk_score_item, :attr, :blank
  end

  test 'unique attributes' do
    risk_score_item = @risk_score_item.dup

    assert risk_score_item.invalid?
    assert_error risk_score_item, :attr, :taken
  end
end
