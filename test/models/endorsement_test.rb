require 'test_helper'

class EndorsementTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @endorsement = endorsements :reschedule
  end

  test 'blank attributes' do
    @endorsement.reason = ''

    assert @endorsement.invalid?
    assert_error @endorsement, :reason, :blank
  end

  test 'sends notification to all on status change' do
    assert_enqueued_emails 1 do
      @endorsement.update! status: 'approved', reason: 'I like it'
    end
  end

  test 'sends notification on creation' do
    assert_enqueued_emails 1 do
      Endorsement.create!(
        user:           users(:administrator),
        finding_answer: finding_answers(:auditor_answer)
      )
    end
  end
end
