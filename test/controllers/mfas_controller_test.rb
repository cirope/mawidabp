require 'test_helper'

class MfasControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:cirope)
    @user         = users :administrator

    set_host_for_organization(@organization.prefix)
  end

  test 'should set google secret' do
    assert_nil @user.google_secret

    set_require_mfa

    assert_not_nil @user.google_secret
  end

  test 'should redirect to mfa after valid login' do
    login

    assert_equal @user.id, @controller.current_user
    assert_redirected_to new_mfa_url
  end

  test 'should redirect to mfa without a valid mfa session' do
    login

    @controller = UsersController.new

    get :index
    assert_redirected_to new_mfa_url
  end

  private

    def set_require_mfa
      org_role = @user.organization_roles.take

      org_role.update! require_mfa: true
    end

    def login
      set_require_mfa

      @controller = SessionsController.new
      post :create, params: { user: @user.user }
      assert_redirected_to signin_url

      @controller = AuthenticationsController.new
      post :create, params: { password: 'admin123' }
    end
end
