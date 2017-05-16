require 'test_helper'

class PeriodTest < ActiveSupport::TestCase
  def setup
    @period = periods :current_period

    set_organization
  end

  test 'create' do
    assert_difference 'Period.count' do
      Period.list.create(
        name: '20',
        description: 'New period',
        start: 2.months.from_now.to_date, # Administrador
        end: 3.months.from_now.to_date
      )
    end
  end

  test 'update' do
    assert @period.update(description: 'Updated period'),
      @period.errors.full_messages.join('; ')
    assert_equal 'Updated period', @period.reload.description
  end

  test 'destroy' do
    assert_difference 'Period.count', -1 do
      periods(:unused_period).destroy
    end
  end

  test 'destroy asociated period' do
    assert_no_difference('Period.count') { @period.destroy }

    assert_equal 3, @period.errors.size
    assert_equal [
      I18n.t('periods.errors.reviews', count: @period.reviews.size),
      I18n.t('periods.errors.plans', count: @period.plans.size),
      I18n.t('periods.errors.workflows', count: @period.workflows.size)
    ].sort, @period.errors.full_messages.sort
  end

  test 'validates formated attributes' do
    @period.start = @period.end = '_1'

    assert @period.invalid?
    assert_error @period, :start, :invalid_date
    assert_error @period, :end, :invalid_date
  end

  test 'validates blank attributes' do
    @period = Period.new name: ' '

    assert @period.invalid?
    assert_error @period, :name, :blank
    assert_error @period, :start, :blank
    assert_error @period, :end, :blank
    assert_error @period, :description, :blank
    assert_error @period, :organization, :blank
  end

  test 'validates relative date attributes' do
    @period.end = @period.start.yesterday

    assert @period.invalid?
    assert_error @period, :end, :after, restriction: I18n.l(@period.start)
  end

  test 'validates duplicated attributes' do
    @period.name = periods(:past_period).name

    assert @period.invalid?
    assert_error @period, :name, :taken
  end

  test 'contains' do
    assert @period.contains?(@period.start)
    assert @period.contains?(@period.end)
    assert !@period.contains?(nil)
    assert !@period.contains?(@period.end + 1.day)
    assert !@period.contains?(@period.start - 1.day)
  end
end
