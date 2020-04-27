require 'test_helper'

class CommitmentSupportTest < ActiveSupport::TestCase
  setup do
    @commitment_support = commitment_supports :excuse
  end

  test 'blank attributes' do
    @commitment_support.reason   = ''
    @commitment_support.plan     = ''
    @commitment_support.controls = ''

    assert @commitment_support.invalid?
    assert_error @commitment_support, :reason, :blank
    assert_error @commitment_support, :plan, :blank
    assert_error @commitment_support, :controls, :blank
  end
end
