require 'test_helper'

class AuthenticationTest < ActionController::TestCase
  fixtures :users, :roles, :organizations

  def setup
    @user = users :administrator_user
    @organization = organizations :default_organization
    @params = { user: @user.user, password: ::PLAIN_PASSWORDS[@user.user] }
    Organization.current_id = @organization.id
  end

  test 'should authenticate admin mode' do
    @auth = Authentication.new @params, request, session, @organization, true

    assert_valid_authentication redirect_url: Group
  end

  test 'should authenticate normal mode' do
    @auth = Authentication.new @params, request, session, @organization, false

    assert_valid_authentication
  end

  test 'should show message days for password expiration' do
    @user.update_column :password_changed, 28.days.ago
    @auth = Authentication.new @params, request, session, @organization, false

    days_for_password_expiration = @user.days_for_password_expiration
    message = I18n.t(days_for_password_expiration >= 0 ? 'message.password_expire_in_x' :
      'message.password_expired_x_days_ago', count: days_for_password_expiration.abs)

    assert_valid_authentication message: message
  end

  test 'should show message must change the password' do
    @user.update_column :password_changed, get_test_parameter(
      :password_expire_time).to_i.next.days.ago
    @auth = Authentication.new @params, request, session, @organization, false

    assert_valid_authentication redirect_url: ['edit_password', @user],
      message: I18n.t('message.must_change_the_password')
  end

  test 'should show message pending poll' do
    user = users :poll_user
    params = { user: user.user, password: ::PLAIN_PASSWORDS[user.user] }
    poll = user.first_pending_poll
    poll_redirect = ['edit', poll, token: poll.access_token, layout: 'clean']
    @auth = Authentication.new params, request, session, @organization, false

    assert_valid_authentication redirect_url: poll_redirect,
      message: I18n.t('poll.must_answer_poll')
  end

  test 'should not login with invalid password' do
    @params = { user: @user.user, password: 'wrong password' }
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication
  end

  test 'should not login if user expired' do
    @user.update_column :last_access,
      get_test_parameter(:account_expire_time).to_i.days.ago.yesterday
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication
    assert !@user.reload.enable?
  end

  test 'should not login user as disabled' do
    @user.update_column :enable, false
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication
  end

  test 'should not login user as hidden' do
    @user.update_column :hidden, true
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication
  end

  test 'should not login with hashed password' do
    @params = { user: @user.user, password: @user.password }
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication
  end

  test 'should not login concurrent users' do
    setting = @organization.settings.find_by name: 'allow_concurrent_sessions'
    setting.update_column :value, 0
    @user.update! last_access: 1.minute.ago, logged_in: true
    @auth = Authentication.new @params, request, session, @organization, false

    assert_invalid_authentication message: I18n.t('message.you_are_already_logged')
  end

  private

    def assert_valid_authentication redirect_url: nil, message: nil
      assert_difference 'LoginRecord.count' do
        assert @auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'welcome', action: 'index'], @auth.redirect_url
        assert_equal message || I18n.t('message.welcome'), @auth.message
      end
    end

    def assert_invalid_authentication redirect_url: nil, message: nil
      assert_difference 'ErrorRecord.count' do
        assert !@auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'sessions', action: 'new'], @auth.redirect_url
        assert_equal message || I18n.t('message.invalid_user_or_password'), @auth.message
        assert_kind_of ErrorRecord, error_record(:on_login)
      end
    end

    def error_record error_type
      ErrorRecord.where(user_id: @user.id, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end
end
