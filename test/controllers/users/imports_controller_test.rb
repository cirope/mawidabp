require 'test_helper'

class Users::ImportsControllerTest < ActionController::TestCase
  setup do
    set_organization organizations(:google)
    login user: users(:administrator), prefix: organizations(:google).prefix
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create import' do
    assert_difference 'User.count' do
      post :create, params: {
        import: { username: 'admin', password: 'admin123' }
      }
      assert_response :success
      assert assigns(:imports).present?
    end
  end

  test 'should create import with alternative ldap' do
    ldap_config = Current.organization.ldap_config

    ldap_config.update_columns(
      hostname:             '0.0.0.1',
      alternative_hostname: 'localhost',
      alternative_port:     ldap_port
    )

    assert_difference 'User.count' do
      post :create, params: {
        import: { username: 'admin', password: 'admin123' }
      }
      assert_response :success
      assert assigns(:imports).present?
    end
  end

  test 'should not create import' do
    assert_no_difference 'User.count' do
      post :create, params: {
        import: { username: 'admin', password: 'wrong' }
      }
      assert_redirected_to new_users_import_url
    end
  end
end
