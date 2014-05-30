require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  fixtures :users, :roles, :organizations

  def setup
    @organization = organizations(:cirope)
    @user = users :administrator_user

    @request.host = "#{@organization.prefix}.localhost.i"
  end

  test "should get login" do
    get :new
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'login without organization' do
    @request.host = 'localhost.i'
    post :create, user: @user.user, password: ::PLAIN_PASSWORDS[@user.user]

    assert_redirected_to login_url
    assert_equal I18n.t('message.no_organization'), flash.alert
  end

  test 'excede maximun number off wrong attempts' do
    max_attempts =
      @user.get_parameter(:attempts_count, false, @organization.id).to_i

    assert_difference 'ErrorRecord.count', max_attempts + 1 do
      max_attempts.times do
        post :create, user: @user.user, password: 'wrong password'

        assert_kind_of ErrorRecord, error_record(:on_login)
        assert_redirected_to login_url
        assert_equal I18n.t('message.invalid_user_or_password'), flash.alert
      end

      assert_redirected_to login_url
      assert_kind_of ErrorRecord, error_record(:user_disabled)
      assert_equal max_attempts, @user.reload.failed_attempts
      assert !@user.enable?
    end
  end

  test 'redirected instead of relogin' do
    post :create, user: @user.user, password: ::PLAIN_PASSWORDS[@user.user]

    assert_redirected_to welcome_url
    get :new
    assert_redirected_to welcome_url
  end

  test 'first login' do
    user = users :first_time_user

    assert_difference 'LoginRecord.count' do
      post :create, user: user.user, password: ::PLAIN_PASSWORDS[user.user]
    end
    assert_redirected_to edit_password_user_url(user)

    login_record = LoginRecord.find_by user: user, organization: @organization
    assert_kind_of LoginRecord, login_record
  end

  test 'logout' do
    login

    delete :destroy
    assert_nil session[:user_id]
    assert_redirected_to login_url
  end

  private

    def error_record error_type
      ErrorRecord.where(user: @user, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end
end
