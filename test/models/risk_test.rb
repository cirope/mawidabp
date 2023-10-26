require 'test_helper'

class RiskTest < ActiveSupport::TestCase
  setup do
    @risk = risks :one
  end

  test 'blank attributes' do
    @risk.attr = ''

    assert @risk.invalid?
    assert_error @risk, :attr, :blank
  end

  test 'unique attributes' do
    risk = @risk.dup

    assert risk.invalid?
    assert_error risk, :attr, :taken
  end
end
