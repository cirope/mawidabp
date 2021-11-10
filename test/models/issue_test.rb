require 'test_helper'

class IssueTest < ActiveSupport::TestCase
  setup do
    @issue = issues :suspicious_transaction
  end

  test 'blank attributes' do
    @issue.finding = nil

    assert @issue.invalid?
    assert_error @issue, :finding, :blank
  end

  test 'numeric attributes' do
    @issue.amount = 'xxx'

    assert @issue.invalid?
    assert_error @issue, :amount, :not_a_number
  end

  test 'validates attributes encoding' do
    @issue.customer    = "\n\t"
    @issue.entry       = "\n\t"
    @issue.operation   = "\n\t"
    @issue.currency    = "\n\t"
    @issue.comments    = "\n\t"

    assert @issue.invalid?
    assert_error @issue, :customer, :pdf_encoding
    assert_error @issue, :entry, :pdf_encoding
    assert_error @issue, :operation, :pdf_encoding
    assert_error @issue, :currency, :pdf_encoding
    assert_error @issue, :comments, :pdf_encoding
  end

  test 'attributes length' do
    @issue.customer  = 'abcde' * 52
    @issue.entry     = 'abcde' * 52
    @issue.operation = 'abcde' * 52
    @issue.currency = 'abcde' * 52

    assert @issue.invalid?
    assert_error @issue, :customer, :too_long, count: 255
    assert_error @issue, :entry, :too_long, count: 255
    assert_error @issue, :operation, :too_long, count: 255
    assert_error @issue, :currency, :too_long, count: 255
  end

  test 'validates well formated attributes' do
    @issue.close_date = '13/13/13'

    assert @issue.invalid?
    assert_error @issue, :close_date, :invalid_date
  end
end
