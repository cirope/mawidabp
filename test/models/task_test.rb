require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @task = tasks :setup_all_things
  end

  test 'blank attributes' do
    @task.code = ''
    @task.description = ''
    @task.due_on = nil
    @task.status = nil

    assert @task.invalid?
    assert_error @task, :code, :blank
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

  test 'warning users about tasks expiration' do
    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?

    @task.update! due_on: FINDING_WARNING_EXPIRE_DAYS.business_days.from_now.to_date

    assert_enqueued_emails @task.users.size do
      Task.warning_users_about_expiration
    end
  end

  test 'remember users about expired tasks' do
    Current.organization = nil

    @task.update! due_on: Time.zone.yesterday

    assert_enqueued_emails @task.users.size do
      Task.remember_users_about_expiration
    end
  end
end
