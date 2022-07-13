# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class EmailReceiverStrategies::ImapPopStrategyTest < ActionController::TestCase
  setup do
    @strategy                = EmailReceiverStrategies::ImapPopStrategy.new
    @old_regex               = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    @old_email_method        = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'
  end

  teardown do
    ENV['REGEX_REPLY_EMAIL'] = @old_regex
    ENV['EMAIL_METHOD']      = @old_email_method
  end

  test 'add answers in findings when receive email' do
    finding       = findings :being_implemented_weakness_on_final
    supervisor    = users :supervisor
    body          = 'Reply On Tuesday wrote: Another reply'
    response_stub = [new_email(supervisor.email, "subject test [##{finding.id}]", body)]

    Mail.stub :all, response_stub do
      @strategy.stub :config, nil do
        assert_difference 'FindingAnswer.count' do
          @strategy.fetch
        end

        assert_equal 'Reply ', finding.finding_answers.last.answer
      end
    end
  end

  test 'should return clean answer before regex' do
    body = 'Reply On Tuesday wrote: Another reply'

    assert_equal 'Reply ', @strategy.clean_answer(new_email('email@test.com', 'subject', body))
  end

  test 'should return - when body is blank' do
    body = ''

    assert_equal '-', @strategy.clean_answer(new_email('email@test.com', 'subject', body))
  end

  test 'should return same body when dont have regex' do
    body = 'Reply test'

    assert_equal body, @strategy.clean_answer(new_email('email@test.com', 'subject', body))
  end

  private

    def new_email from, subject, body
      mail = create_mail from, subject

      mail.text_part = Mail::Part.new do
        body body
      end

      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body          body
      end

      mail
    end

    def create_mail from, subject
      Mail.new do
        from    from
        to      'support@postman.com'
        subject subject
      end
    end
end
