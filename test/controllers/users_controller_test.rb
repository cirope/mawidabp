require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  def setup
    login
  end

  test 'list users' do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'list users with search' do
    get :index, search: { query: 'manager', columns: ['user', 'name'] }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 5, assigns(:users).count
  end

  test 'edit user when search match only one result' do
    get :index, search: { query: 'admin', columns: ['user', 'name'] }
    assert_redirected_to user_url(users(:administrator_user))
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).count
  end

  test 'show user' do
    get :show, id: users(:administrator_user)
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'new user' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'create user' do
    counts_array = ['User.count', 'RelatedUserRelation.count', 'OrganizationRole.count']

    assert_emails 1 do
      assert_difference counts_array do
        post :create, {
          user: {
            user: 'new_user',
            name: 'New Name',
            last_name: 'New Last Name',
            email: 'new_user@newemail.net',
            language: I18n.available_locales.last.to_s,
            notes: 'Some user notes',
            resource_id: resources(:auditor_resource).id,
            manager_id: users(:administrator_user).id,
            logged_in: false,
            enable: true,
            send_notification_email: true,
            organization_roles_attributes: [
              {
                organization_id: organizations(:cirope).id,
                role_id: roles(:admin_role).id
              }
            ],
            related_user_relations_attributes: [
              { related_user_id: users(:plain_manager_user).id }
            ]
          }
        }
      end
    end

    assert_difference ['User.count', 'OrganizationRole.count'] do
      assert_no_emails do
        post :create, {
          user: {
            user: 'new_user_2',
            name: 'New Name2',
            last_name: 'New Last Name2',
            email: 'new_user2@newemail.net',
            language: I18n.available_locales.last.to_s,
            notes: 'Some user notes',
            resource_id: resources(:auditor_resource).id,
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
    end
  end

  test 'edit user' do
    get :edit, id: users(:administrator_user)
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'update user' do
    user = users :administrator_user
    counts_array = ['User.count', 'OrganizationRole.count', 'user.children.count']

    assert_no_emails do
      assert_no_difference counts_array do
        patch :update, {
          id: user.user,
          user: {
            user: 'updated_name',
            name: 'Updated Name',
            last_name: 'Updated Last Name',
            email: 'updated_user@updatedemail.net',
            notes: 'Updated user notes',
            language: I18n.available_locales.first.to_s,
            resource_id: resources(:auditor_resource).id,
            logged_in: false,
            enable: true,
            send_notification_email: false,
            organization_roles_attributes: [
              {
                id: organization_roles(:admin_role_for_administrator_user_in_cirope).id,
                organization_id: organizations(:cirope).id,
                role_id: roles(:admin_role).id
              }
            ],
            child_ids: [
              users(:administrator_second_user).id,
              users(:bare_user).id,
              users(:first_time_user).id,
              users(:expired_user).id,
              users(:disabled_user).id,
              users(:blank_password_user).id,
              users(:expired_blank_password_user).id,
              users(:supervisor_user).id,
              users(:supervisor_second_user).id,
              users(:committee_user).id
            ]
          }
        }
      end
    end

    assert_redirected_to users_url
    assert_not_nil assigns(:user)
    assert_equal 'updated_name', assigns(:user).user
  end

  test 'send notification on updated user' do
    user = users :administrator_user

    assert_no_difference ['User.count', 'user.children.count'] do
      assert_emails 1 do
        assert_difference 'OrganizationRole.count' do
          patch :update, {
            id: users(:administrator_user).user,
            user: {
              user: 'updated_name_2',
              name: 'Updated Name',
              last_name: 'Updated Last Name',
              email: 'updated_user@updatedemail.net',
              language: I18n.available_locales.first.to_s,
              notes: 'Updated user notes',
              resource_id: resources(:auditor_resource).id,
              logged_in: false,
              enable: true,
              send_notification_email: true,
              organization_roles_attributes: [
                {
                  organization_id: organizations(:cirope).id,
                  role_id: roles(:admin_second_role).id
                }
              ],
              child_ids: [
                users(:administrator_second_user).id,
                users(:bare_user).id,
                users(:first_time_user).id,
                users(:expired_user).id,
                users(:disabled_user).id,
                users(:blank_password_user).id,
                users(:expired_blank_password_user).id,
                users(:supervisor_user).id,
                users(:supervisor_second_user).id,
                # El siguiente se elimina
                users(:committee_user).id
              ]
            }
          }
        end
      end
    end

    assert_redirected_to users_url
    assert_not_nil assigns(:user)
    assert_equal 'updated_name_2', assigns(:user).user
  end

  test 'disable user' do
    user = users :supervisor_second_user

    assert user.enable?
    assert user.findings.all_for_reallocation.empty?

    assert_no_difference 'User.count' do
      delete :destroy, id: user
    end

    assert !user.reload.enable?
    assert_redirected_to users_url
  end

  test 'disable audited user' do
    assert_no_difference 'User.count' do
      delete :destroy, id: users(:audited_user).user
    end

    assert_redirected_to users_url
  end

  test 'index as pdf' do
    get :index, format: :pdf
    assert_redirected_to UserPdf.new.relative_path
  end

  test 'export with search' do
    get :index, format: :pdf, search: {
      query: 'manager', columns: ['user', 'name']
    }

    assert_redirected_to UserPdf.new.relative_path
  end

  test 'auto complete for user' do
    get :auto_complete_for_user, { q: 'admin', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Administrator
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :auto_complete_for_user, { q: 'blank', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size # Blank and Expired blank
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }

    post :auto_complete_for_user, { q: 'xyz', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end
end
