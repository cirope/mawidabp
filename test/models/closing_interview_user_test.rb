require 'test_helper'

class ClosingInterviewUserTest < ActiveSupport::TestCase
  setup do
    @closing_interview_user = closing_interview_users :admin_on_current
  end

  test 'blank attributes' do
    @closing_interview_user.closing_interview = nil
    @closing_interview_user.user = nil

    assert @closing_interview_user.invalid?
    assert_error @closing_interview_user, :closing_interview, :blank
    assert_error @closing_interview_user, :user, :blank
  end
end
