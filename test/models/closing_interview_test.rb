require 'test_helper'

class ClosingInterviewTest < ActiveSupport::TestCase
  setup do
    @closing_interview = closing_interviews :current
  end

  test 'blank attributes' do
    @closing_interview.interview_date = nil
    @closing_interview.review_id = nil

    assert @closing_interview.invalid?
    assert_error @closing_interview, :interview_date, :blank
    assert_error @closing_interview, :review_id, :blank
  end

  test 'formated attributes' do
    @closing_interview.interview_date = '13/13/13'

    assert @closing_interview.invalid?
    assert_error @closing_interview, :interview_date, :invalid_date
  end

  test 'attributes encoding' do
    @closing_interview.findings_summary = "\n\t"
    @closing_interview.recommendations_summary = "\n\t"
    @closing_interview.suggestions = "\n\t"
    @closing_interview.comments = "\n\t"
    @closing_interview.audit_comments = "\n\t"
    @closing_interview.responsible_comments = "\n\t"

    assert @closing_interview.invalid?
    assert_error @closing_interview, :findings_summary, :pdf_encoding
    assert_error @closing_interview, :recommendations_summary, :pdf_encoding
    assert_error @closing_interview, :suggestions, :pdf_encoding
    assert_error @closing_interview, :comments, :pdf_encoding
    assert_error @closing_interview, :audit_comments, :pdf_encoding
    assert_error @closing_interview, :responsible_comments, :pdf_encoding
  end
end
