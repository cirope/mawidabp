require 'test_helper'

class LoginRecordTest < ActiveSupport::TestCase
  fixtures :login_records, :users

  def setup
    set_organization

    @login_record = LoginRecord.find(
      login_records(:administrator_user_success_login_record).id)
  end

  test 'search' do
    assert_kind_of LoginRecord, @login_record
    assert_equal login_records(:administrator_user_success_login_record).start,
      @login_record.start
    assert_equal login_records(:administrator_user_success_login_record).end,
      @login_record.end
    assert_equal login_records(:administrator_user_success_login_record).data,
      @login_record.data
    assert_equal login_records(:administrator_user_success_login_record).user_id,
      @login_record.user_id
    assert_equal login_records(:administrator_user_success_login_record).
      organization_id, @login_record.organization_id
  end

  test 'create' do
    assert_difference 'LoginRecord.count' do
      @login_record = LoginRecord.list.create(
        :start => 2.hours.ago,
        :end => Time.now,
        :user_id => users(:administrator_user).id,
        :data => 'Some data'
      )
    end
  end

  test 'update' do
    assert @login_record.update(:data => 'New data'),
      @login_record.errors.full_messages.join('; ')
    @login_record.reload
    assert_equal 'New data', @login_record.data
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
    assert_error @login_record, :end, :after, restriction: I18n.l(@login_record.start, format: :validation)

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
