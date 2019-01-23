require 'test_helper'

class OpeningInterviewTest < ActiveSupport::TestCase
  setup do
    @opening_interview = opening_interviews :current
  end

  test 'blank attributes' do
    @opening_interview.interview_date = nil
    @opening_interview.start_date = nil
    @opening_interview.end_date = nil
    @opening_interview.objective = ''
    @opening_interview.review_id = nil

    assert @opening_interview.invalid?
    assert_error @opening_interview, :interview_date, :blank
    assert_error @opening_interview, :start_date, :blank
    assert_error @opening_interview, :end_date, :blank
    assert_error @opening_interview, :objective, :blank
    assert_error @opening_interview, :review_id, :blank
  end

  test 'formated attributes' do
    @opening_interview.start_date = '13/13/13'
    @opening_interview.end_date = '13/13/13'

    assert @opening_interview.invalid?
    assert_error @opening_interview, :start_date, :invalid_date
    assert_error @opening_interview, :end_date, :invalid_date
  end

  test 'attributes encoding' do
    @opening_interview.objective = "\n\t"
    @opening_interview.program = "\n\t"
    @opening_interview.scope = "\n\t"
    @opening_interview.suggestions = "\n\t"
    @opening_interview.comments = "\n\t"

    assert @opening_interview.invalid?
    assert_error @opening_interview, :objective, :pdf_encoding
    assert_error @opening_interview, :program, :pdf_encoding
    assert_error @opening_interview, :scope, :pdf_encoding
    assert_error @opening_interview, :suggestions, :pdf_encoding
    assert_error @opening_interview, :comments, :pdf_encoding
  end
end
