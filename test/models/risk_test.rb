require 'test_helper'

class RiskTest < ActiveSupport::TestCase
  setup do
    @risk = risks :risk
  end

  test 'blank attributes' do
    @risk.identifier = ''
    @risk.name = ''
    @risk.likelihood = ''
    @risk.impact = ''

    assert @risk.invalid?
    assert_error @risk, :identifier, :blank
    assert_error @risk, :name, :blank
    assert_error @risk, :likelihood, :blank
    assert_error @risk, :impact, :blank
  end

  test 'attribute length' do
    @risk.name = 'abcde' * 52
    @risk.identifier = 'abcde' * 52

    assert @risk.invalid?
    assert_error @risk, :name, :too_long, count: 255
    assert_error @risk, :identifier, :too_long, count: 255
  end

  test 'included attributes' do
    @risk.likelihood = -1
    @risk.impact = -1

    assert @risk.invalid?
    assert_error @risk, :likelihood, :inclusion
    assert_error @risk, :impact, :inclusion
  end
end
