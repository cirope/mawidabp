require 'test_helper'

class ProcessControlCommentTest < ActiveSupport::TestCase
  def setup
    @process_control_comment = process_control_comments :security_policy_on_current
  end

  test 'blank attributes' do
    @process_control_comment.auditor_comment = '   '
    @process_control_comment.process_control = nil

    assert @process_control_comment.invalid?
    assert_error @process_control_comment, :auditor_comment, :blank
    assert_error @process_control_comment, :process_control, :blank
  end
end
