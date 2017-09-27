require 'test_helper'

class LoginRecordTest < ActiveSupport::TestCase
  setup do
    set_organization

    @login_record = LoginRecord.find(
      login_records(:administrator_success_login_record).id)
  end

  test 'create' do
    assert_difference 'LoginRecord.count' do
      @login_record = LoginRecord.list.create(
        start: 2.hours.ago,
        end: Time.now,
        user_id: users(:administrator).id,
        data: 'Some data'
      )
    end
  end

  test 'update' do
    assert @login_record.update(data: 'New data'),
      @login_record.errors.full_messages.join('; ')

    assert_equal 'New data', @login_record.reload.data
  end

  test 'destroy' do
    assert_difference 'LoginRecord.count', -1 do
      @login_record.destroy
    end
  end

  test 'validates blank attributes' do
    @login_record = LoginRecord.new user: nil

    assert @login_record.invalid?
    assert_error @login_record, :user, :blank
    assert_error @login_record, :organization, :blank
  end

  test 'validates dates attributes' do
    @login_record.start = Time.now
    @login_record.end = 10.hours.ago

    assert @login_record.invalid?
    assert_error @login_record, :end, :after,
      restriction: I18n.l(@login_record.start, format: :validation)

    @login_record.reload
    @login_record.start = 'XX'

    assert @login_record.invalid?
    assert_error @login_record, :start, :blank
    assert_error @login_record, :start, :invalid_datetime

    @login_record.reload
    @login_record.start = ''
    @login_record.end = ''

    assert @login_record.invalid?
    assert_error @login_record, :start, :blank
    assert_error @login_record, :end, :invalid_datetime
  end
end
