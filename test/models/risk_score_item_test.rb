require 'test_helper'

class RiskScoreItemTest < ActiveSupport::TestCase
  setup do
    @risk_score_item = risk_score_items :sox_404a
  end

  test 'blank attributes' do
    @risk_score_item.name = ''
    @risk_score_item.value = ''

    assert @risk_score_item.invalid?
    assert_error @risk_score_item, :name, :blank
    assert_error @risk_score_item, :value, :blank
  end

  test 'attributes length' do
    @risk_score_item.name = 'abcde' * 52

    assert @risk_score_item.invalid?
    assert_error @risk_score_item, :name, :too_long, count: 255
  end

  test 'unique attributes' do
    risk_score_item = @risk_score_item.dup

    assert risk_score_item.invalid?
    assert_error risk_score_item, :name, :taken
  end

  test 'attributes boundaries' do
    @risk_score_item.value = -1

    assert @risk_score_item.invalid?
    assert_error @risk_score_item, :value, :greater_than_or_equal_to, count: 0
  end
end
