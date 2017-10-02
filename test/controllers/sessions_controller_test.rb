require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:cirope)
    @user = users :administrator

    @request.host = "#{@organization.prefix}.localhost.i"
  end

  test 'should get login' do
    get :new
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'login without organization' do
    @request.host = 'localhost.i'
    post :create, params: {
      user: @user.user,
      password: 'admin123'
    }

    assert_redirected_to login_url
    assert_equal I18n.t('message.no_organization'), flash.alert
  end

  test 'redirected instead of relogin' do
    post :create, params: {
      user: @user.user,
      password: 'admin123'
    }

    assert_redirected_to welcome_url
    get :new
    assert_redirected_to welcome_url
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
