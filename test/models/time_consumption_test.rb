require 'test_helper'

class TimeConsumptionTest < ActiveSupport::TestCase
  setup do
    @time_consumption = time_consumptions :special_activity_time
  end

  test 'blank attributes' do
    @time_consumption.date = ''
    @time_consumption.amount = ''

    assert @time_consumption.invalid?
    assert_error @time_consumption, :date, :blank
    assert_error @time_consumption, :amount, :blank
  end

  test 'bounded attributes' do
    @time_consumption.amount = -1

    assert @time_consumption.invalid?
    assert_error @time_consumption, :amount, :greater_than, count: 0

    @time_consumption.amount = 25
    @time_consumption.resource.require_detail = true

    assert @time_consumption.invalid?
    assert_error @time_consumption, :amount, :less_than_or_equal_to, count: 24.0
    assert_error @time_consumption, :detail, :blank
  end

  test 'custom amount limit' do
    @time_consumption.limit  = 7.0
    @time_consumption.amount = @time_consumption.limit + 1

    assert @time_consumption.invalid?
    assert_error @time_consumption, :amount, :less_than_or_equal_to, count: 7.0
  end

  test 'validates formated attributes' do
    @time_consumption.date = '13/13/13'

    assert @time_consumption.invalid?
    assert_error @time_consumption, :date, :invalid_date
  end
end
