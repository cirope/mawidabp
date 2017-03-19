require 'test_helper'

class Users::RegistrationsControllerTest < ActionController::TestCase
  setup do
    @request.host = "#{organizations(:cirope).prefix}.localhost.i"
  end

  test 'new' do
    get :new, params: { hash: groups(:main_group).admin_hash }
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'new with invalid hash' do
    assert_raise ActiveRecord::RecordNotFound do
      get :new, params: { hash: 'xxx' }
    end
  end

  test 'new with stale hash' do
    group = groups :main_group

    group.update! updated_at: BLANK_PASSWORD_STALE_DAYS.next.days.ago

    get :new, params: { hash: group.admin_hash }
    assert_redirected_to login_url
  end

  test 'create initial' do
    assert_difference ['User.count', 'OrganizationRole.count'] do
      post :create, params: {
        hash: groups(:main_group).admin_hash,
        user: {
          user: 'new_user_2',
          name: 'New Name2',
          last_name: 'New Last Name2',
          email: 'new_user2@newemail.net',
          language: I18n.available_locales.last.to_s,
          manager_id: users(:administrator_user).id,
          logged_in: false,
          enable: true,
          send_notification_email: false,
          organization_roles_attributes: [
            {
              organization_id: organizations(:cirope).id,
              role_id: roles(:admin_role).id
            }
          ]
        }
      }
    end

    assert_redirected_to login_url
    assert_equal I18n.t('flash.actions.create.notice', resource_name: User.model_name.human),
      flash.notice
  end

  test 'create with invalid hash' do
    assert_raise ActiveRecord::RecordNotFound do
      post :create, params: {
        hash: 'xxx',
        user: {}
      }
    end
  end
end
