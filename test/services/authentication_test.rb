require 'test_helper'

class AuthenticationTest < ActionController::TestCase
  def setup
    @user = users :administrator_user
    @organization = organizations :cirope
    @params = { user: @user.user, password: 'admin123' }
    Organization.current_id = @organization.id
  end

  test 'should authenticate' do
    assert_valid_authentication redirect_url: Group, admin_mode: true
    assert_valid_authentication
  end

  test 'should authenticate via ldap' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'admin123' }
    Organization.current_id = @organization.id

    assert_valid_authentication
  end

  test 'no group admin user attempt login in admin mode' do
    request.host = "#{APP_ADMIN_PREFIXES.first}.localhost.i"
    @user.update_column :group_admin, false

    assert_invalid_authentication admin_mode: true
  end

  test 'should show message days for password expiration' do
    password_changed = get_test_parameter(:expire_notification).to_i.next.days.ago
    @user.update_column :password_changed, password_changed

    days_for_password_expiration = @user.days_for_password_expiration
    message = [days_for_password_expiration >= 0 ?
      'message.password_expire_in_x' : 'message.password_expired_x_days_ago',
      count: days_for_password_expiration.abs]

    assert_valid_authentication message: message
  end

  test 'should show message must change the password' do
    @user.update_column :password_changed, get_test_parameter(:password_expire_time).to_i.next.days.ago

    assert_valid_authentication redirect_url: [:edit, 'users_password', id: @user],
      message: 'message.must_change_the_password'
  end

  test 'should show message pending poll' do
    Poll.first.update_column :user_id, @user.id
    poll = @user.first_pending_poll
    poll_redirect = ['edit', poll, token: poll.access_token]

    assert_valid_authentication redirect_url: poll_redirect,
      message: 'polls.must_answer_poll'
  end

  test 'should not login with invalid password' do
    @params = { user: @user.user, password: 'wrong password' }

    assert_invalid_authentication
    assert_invalid_authentication admin_mode: true
  end

  test 'should not authenticate via ldap with invalid password' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'wrong password' }
    Organization.current_id = @organization.id

    assert_invalid_authentication
  end

  test 'should show a message when ldap is not reacheble' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'wrong password' }
    Organization.current_id = @organization.id

    @organization.ldap_config.update port: 1

    assert_invalid_authentication message: 'message.ldap_error'
  end

  test 'should not login if user expired' do
    @user.update_column :last_access,
      get_test_parameter(:account_expire_time).to_i.days.ago.yesterday

    assert_invalid_authentication
    assert !@user.reload.enable?
  end

  test 'should not login user as disabled' do
    @user.update_column :enable, false

    assert_invalid_authentication
    assert_invalid_authentication admin_mode: true
  end

  test 'should not login user as hidden' do
    @user.update_column :hidden, true

    assert_invalid_authentication
  end

  test 'should not login with hashed password' do
    @params = { user: @user.user, password: @user.password }

    assert_invalid_authentication
  end

  test 'should not login concurrent users' do
    setting = @organization.settings.find_by name: 'allow_concurrent_sessions'
    setting.update_column :value, 0
    @user.update! last_access: 1.minute.ago, logged_in: true

    assert_invalid_authentication message: 'message.you_are_already_logged'
  end

  test 'excede maximun number off wrong attempts' do
    max_attempts =
      @user.get_parameter(:attempts_count, false, @organization.id).to_i
    @params = { user: @user.user, password: 'wrong password' }

    assert_difference 'ErrorRecord.count', max_attempts.next do
      max_attempts.pred.times { assert_invalid_authentication }
      @auth = Authentication.new @params, request, session, @organization, false
      @auth.authenticated?
    end

    assert_kind_of ErrorRecord, error_record(:user_disabled)
    assert_equal max_attempts, @user.reload.failed_attempts
    assert !@user.enable?
  end

  test 'first login' do
    @user.update_column :last_access, nil

    assert_valid_authentication redirect_url: [:edit, 'users_password', id: @user],
      message: 'message.must_change_the_password'

    login_record = LoginRecord.find_by user: @user, organization: @organization
    assert_kind_of LoginRecord, login_record
  end

  private

    def assert_valid_authentication redirect_url: nil, message: nil, admin_mode: false
      @auth = Authentication.new @params, request, session, @organization, admin_mode

      assert_difference 'LoginRecord.count' do
        assert @auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'welcome', action: 'index'], @auth.redirect_url
        assert_equal I18n.t(*message || 'message.welcome'), @auth.message
      end
    end

    def assert_invalid_authentication redirect_url: nil, message: nil, admin_mode: false
      @auth = Authentication.new @params, request, session, @organization, admin_mode

      assert_difference 'ErrorRecord.count' do
        assert !@auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'sessions', action: 'new'], @auth.redirect_url
        assert_equal I18n.t(*message || 'message.invalid_user_or_password'), @auth.message
        assert_kind_of ErrorRecord, error_record(:on_login)
      end
    end

    def error_record error_type
      ErrorRecord.where(user: @user, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end
end
