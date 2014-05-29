require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  fixtures :users, :roles, :organizations

  def setup
    @organization = organizations(:cirope)

    @request.host = "#{@organization.prefix}.localhost.i"
  end

  test "should get login" do
    get :new
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'invalid user and password attempt' do
    assert_difference 'ErrorRecord.count' do
      post :create, :user => 'someone', :password => 'without authorization'

      error_record = ErrorRecord.where(
        'data LIKE :data', :data => '%someone%'
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_redirected_to login_url
      assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
    end
  end

  test 'invalid user and password attempt in admin mode' do
    @request.host = "#{APP_ADMIN_PREFIXES.first}.localhost.i"

    assert_difference 'ErrorRecord.count' do
      post :create, :user => 'someone', :password => 'without authorization'

      error_record = ErrorRecord.where(
        'data LIKE :data', :data => '%someone%'
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_redirected_to login_url
      assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
    end
  end

  test 'invalid password attempt in admin mode' do
    @request.host = "#{APP_ADMIN_PREFIXES.first}.localhost.i"

    assert_difference 'ErrorRecord.count' do
      post :create, :user => users(:administrator_user).user,
        :password => 'wrong password'

      error_record = ErrorRecord.where(
        :user_id => users(:administrator_user).id,
        :error => ErrorRecord::ERRORS[:on_login]
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_redirected_to login_url
      assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
    end
  end

  test 'disabled user attempt in admin mode' do
    @request.host = "#{APP_ADMIN_PREFIXES.first}.localhost.i"

    assert_difference 'ErrorRecord.count' do
      post :create, :user => users(:disabled_user).user,
        :password => ::PLAIN_PASSWORDS[users(:disabled_user).user]

      error_record = ErrorRecord.where(
        :user_id => users(:disabled_user).id,
        :error => ErrorRecord::ERRORS[:on_login]
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_redirected_to login_url
      assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
    end
  end

  test 'no group admin user attempt in admin mode' do
    @request.host = "#{APP_ADMIN_PREFIXES.first}.localhost.i"

    assert_difference 'ErrorRecord.count' do
      post :create, :user => users(:administrator_second_user).user,
        :password => ::PLAIN_PASSWORDS[users(:administrator_second_user).user]

      error_record = ErrorRecord.where(
        :user_id => users(:administrator_second_user).id,
        :error => ErrorRecord::ERRORS[:on_login]
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_redirected_to login_url
      assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
    end
  end

  test 'excede maximun number off wrong attempts' do
    user = User.find users(:administrator_user).id
    max_attempts = user.get_parameter(
      :attempts_count, false, @organization.id
    ).to_i

    assert_difference 'ErrorRecord.count', max_attempts + 1 do
      max_attempts.times do
        post :create, :user => user.user, :password => 'wrong password'

        error_record = ErrorRecord.where(
          :user_id => user.id, :error => ErrorRecord::ERRORS[:on_login]
        ).order('created_at DESC').first
        assert_kind_of ErrorRecord, error_record
        assert_redirected_to login_url
        assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
      end

      assert_redirected_to login_url
      error_record = ErrorRecord.where(
        :user_id => users(:administrator_user).id,
        :error => ErrorRecord::ERRORS[:user_disabled]
      ).order('created_at DESC').first
      assert_kind_of ErrorRecord, error_record
      assert_equal max_attempts, user.reload.failed_attempts
      assert !user.enable?
    end
  end

  test 'login without organization' do
    @request.host = 'localhost.i'

    post :create, :user => users(:administrator_user).user,
      :password => ::PLAIN_PASSWORDS[users(:administrator_user).user]

    assert_redirected_to login_url
    assert_equal I18n.t('message.no_organization'), flash.alert
  end

  test 'expired password' do
    user = User.find users(:administrator_user).id
    user.update_attribute :password_changed,
      get_test_parameter(:password_expire_time).to_i.next.days.ago

    post :create, :user => users(:administrator_user).user,
      :password => ::PLAIN_PASSWORDS[users(:administrator_user).user]

    assert_redirected_to edit_password_user_url(user)
  end

  test 'warning about password expiration' do
    password_changed = get_test_parameter(
      :expire_notification).to_i.next.days.ago
    user = User.find users(:administrator_user).id

    user.update_attribute :password_changed, password_changed

    post :create, :user => users(:administrator_user).user,
      :password => ::PLAIN_PASSWORDS[users(:administrator_user).user]

    assert_redirected_to welcome_url
    login_record = LoginRecord.where(
      :user_id => users(:administrator_user).id,
      :organization_id => organizations(:cirope).id
    ).first
    assert_kind_of LoginRecord, login_record
    assert_not_nil I18n.t('message.password_expire_in_x',
      :count => get_test_parameter(:expire_notification).to_i - 2),
      flash.notice
  end

  test 'redirected instead of relogin' do
    post :create, :user => users(:administrator_user).user,
      :password => ::PLAIN_PASSWORDS[users(:administrator_user).user]

    assert_redirected_to welcome_url
    get :new
    assert_redirected_to welcome_url
  end

  test 'first login' do
    assert_difference 'LoginRecord.count' do
      post :create, :user => users(:first_time_user).user,
        :password => ::PLAIN_PASSWORDS[users(:first_time_user).user]
    end

    assert_redirected_to edit_password_user_url(users(:first_time_user))
    login_record = LoginRecord.where(
      :user_id => users(:first_time_user).id,
      :organization_id => organizations(:cirope).id
    ).first
    assert_kind_of LoginRecord, login_record
  end

  test 'logout' do
    login
    delete :destroy
    assert_nil session[:user_id]
    assert_redirected_to login_url
  end
end
