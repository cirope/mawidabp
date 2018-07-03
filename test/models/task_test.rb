require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  setup do
    @task = tasks :setup_all_things
  end

  test 'blank attributes' do
    @task.description = ''
    @task.due_on = nil
    @task.status = nil

    assert @task.invalid?
    assert_error @task, :description, :blank
    assert_error @task, :due_on, :blank
    assert_error @task, :status, :blank
  end

  test 'validates attributes encoding' do
    @task.description = "\n\t"

    assert @task.invalid?
    assert_error @task, :description, :pdf_encoding
  end

  test 'validates well formated attributes' do
    @task.due_on = '13/13/13'

    assert @task.invalid?
    assert_error @task, :due_on, :invalid_date
  end

  test 'list all due on dates' do
    old_date = @task.due_on

    assert @task.all_due_on_dates.blank?

    @task.update! due_on: 10.days.from_now.to_date

    assert @task.all_due_on_dates.include?(old_date)

    @task.update! due_on: 15.days.from_now.to_date

    assert @task.all_due_on_dates.include?(old_date)
    assert @task.all_due_on_dates.include?(10.days.from_now.to_date)
  end
end
