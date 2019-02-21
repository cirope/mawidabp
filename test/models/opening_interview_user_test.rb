require 'test_helper'

class OpeningInterviewUserTest < ActiveSupport::TestCase
  setup do
    @opening_interview_user = opening_interview_users :admin_on_current
  end

  test 'blank attributes' do
    @opening_interview_user.user = nil

    assert @opening_interview_user.invalid?
    assert_error @opening_interview_user, :user, :blank
  end
end
