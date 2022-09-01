require 'test_helper'

class ReadingTest < ActiveSupport::TestCase
  setup do
    @reading = readings :administrator_on_auditor_answer
  end

  test 'blank attributes' do
    @reading.user = nil
    @reading.readable = nil

    assert @reading.invalid?
    assert_error @reading, :user, :blank
    assert_error @reading, :readable, :blank
  end

  test 'included attributes' do
    @reading.readable_type = 'Review'

    assert @reading.invalid?
    assert_error @reading, :readable_type, :inclusion
  end
end
