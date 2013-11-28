require 'test_helper'

# Pruebas para el controlador de usuarios
class UsersControllerTest < ActionController::TestCase
  fixtures :users, :roles, :organizations

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @request.host = "#{organizations(:default_organization).prefix}.localhost.i"
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => users(:administrator_user).to_param}
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param],
      [:patch, :blank_password, id_param],
      [:get, :edit_password, id_param],
      [:patch, :update_password, id_param],
      [:get, :edit_personal_data, id_param],
      [:patch, :update_personal_data, id_param],
      [:get, :new_initial],
      [:post, :create_initial],
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert [I18n.t('message.must_be_authenticated'),
        I18n.t('user.confirmation_link_invalid')].include?(flash.alert)
    end
  end

  test 'list users' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_select '#error_body', false
    assert_template 'users/index'
  end

  test 'list users with search' do
    perform_auth
    get :index, :search => {:query => 'manager', :columns => ['user', 'name']}
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 5, assigns(:users).size
    assert_select '#error_body', false
    assert_template 'users/index'
  end


  test 'edit user when search match only one result' do
    perform_auth
    get :index, :search => {:query => 'admin', :columns => ['user', 'name']}
    assert_redirected_to user_url(users(:administrator_user))
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size
  end

  test 'show user' do
    perform_auth
    get :show, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/show'
  end

  test 'new user' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/new'
  end

  test 'create user' do
    perform_auth
    counts_array = ['User.count', 'RelatedUserRelation.count',
      'OrganizationRole.count', 'ActionMailer::Base.deliveries.size']
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      post :create, {
        :user => {
          :user => 'new_user',
          :name => 'New Name',
          :last_name => 'New Last Name',
          :email => 'new_user@newemail.net',
          :language => I18n.available_locales.last.to_s,
          :notes => 'Some user notes',
          :resource_id => resources(:auditor_resource).id,
          :manager_id => users(:administrator_user).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => true,
          :organization_roles_attributes => [
            {
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          ],
          :related_user_relations_attributes => [
            { :related_user_id => users(:plain_manager_user).id }
          ]
        }
      }
    end

    assert_difference ['User.count', 'OrganizationRole.count'] do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, {
          :user => {
            :user => 'new_user_2',
            :name => 'New Name2',
            :last_name => 'New Last Name2',
            :email => 'new_user2@newemail.net',
            :language => I18n.available_locales.last.to_s,
            :notes => 'Some user notes',
            :resource_id => resources(:auditor_resource).id,
            :manager_id => users(:administrator_user).id,
            :logged_in => false,
            :enable => true,
            :send_notification_email => false,
            :organization_roles_attributes => [
              {
                :organization_id => organizations(:default_organization).id,
                :role_id => roles(:admin_role).id
              }
            ]
          }
        }
      end
    end
  end

  test 'edit user' do
    perform_auth
    get :edit, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/edit'
  end

  test 'update user' do
    perform_auth

    user = User.find(users(:administrator_user).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    counts_array = ['User.count', 'OrganizationRole.count',
      'ActionMailer::Base.deliveries.size', 'user.children.count']

    assert_no_difference counts_array do
      patch :update, {
        :id => user.user,
        :user => {
          :user => 'updated_name',
          :name => 'Updated Name',
          :last_name => 'Updated Last Name',
          :email => 'updated_user@updatedemail.net',
          :notes => 'Updated user notes',
          :language => I18n.available_locales.first.to_s,
          :resource_id => resources(:auditor_resource).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => false,
          :organization_roles_attributes => [
            {
              :id => organization_roles(:admin_role_for_administrator_user_in_default_organization).id,
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          ],
          :child_ids => [
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

    assert_redirected_to users_url
    assert_not_nil assigns(:user)
    assert_equal 'updated_name', assigns(:user).user
  end

  test 'send notification on updated user' do
    perform_auth

    user = User.find(users(:administrator_user).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference ['User.count', 'user.children.count'] do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        assert_difference 'OrganizationRole.count' do
          patch :update, {
            :id => users(:administrator_user).user,
            :user => {
              :user => 'updated_name_2',
              :name => 'Updated Name',
              :last_name => 'Updated Last Name',
              :email => 'updated_user@updatedemail.net',
              :language => I18n.available_locales.first.to_s,
              :notes => 'Updated user notes',
              :resource_id => resources(:auditor_resource).id,
              :logged_in => false,
              :enable => true,
              :send_notification_email => true,
              :organization_roles_attributes => [
                {
                  :organization_id => organizations(:default_organization).id,
                  :role_id => roles(:admin_second_role).id
                }
              ],
              :child_ids => [
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
    perform_auth
    user = User.find(users(:supervisor_second_user).id)

    assert user.enable?
    assert user.findings.all_for_reallocation.empty?

    assert_no_difference 'User.count' do
      delete :destroy, :id => user.user
    end

    assert !user.reload.enable?
    assert_equal I18n.t('user.correctly_disabled'), flash.notice
    assert_redirected_to users_url
  end

  test 'disable audited user' do
    perform_auth
    assert_no_difference 'User.count' do
      delete :destroy, :id => users(:audited_user).user
    end

    assert_equal I18n.t('user.will_be_orphan_findings'), flash.alert
    assert_redirected_to users_url
  end

  test 'blank user password' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :blank_password, :id => users(:administrator_user).user
    end

    assert_redirected_to users_url
    user = User.find(users(:administrator_user).id)
    assert_not_nil user.change_password_hash
  end

  test 'reset password' do
    get :reset_password
    assert_response :success
    assert_select '#error_body', false
    assert_template 'users/reset_password'
  end

  test 'send password reset' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    original_hash = users(:blank_password_user).change_password_hash

    assert_difference 'ActionMailer::Base.deliveries.size' do
      post :send_password_reset, :email => users(:blank_password_user).email
    end

    assert_redirected_to login_url
    user = User.find(users(:blank_password_user).id)
    assert_not_nil user.change_password_hash
    assert_not_equal original_hash, user.change_password_hash
  end

  test 'edit password' do
    perform_auth
    get :edit_password, {:id => users(:blank_password_user).to_param}
    assert_response :success
    assert_not_nil assigns(:auth_user)
    assert_select '#error_body', false
    assert_template 'users/edit_password'
  end

  test 'update password' do
    perform_auth
    assert_difference 'OldPassword.count' do
      patch :update_password, {
        :id => users(:administrator_user).to_param,
        :user => {
          :password => 'new_password_123',
          :password_confirmation => 'new_password_123'
        }
      }

      user = User.find(users(:administrator_user).id)
      assert_redirected_to login_url
      assert_equal User.digest('new_password_123', user.salt), user.password
    end
  end

  test 'change blank password' do
    get :edit_password, {:id => users(:blank_password_user).user,
      :confirmation_hash => users(:blank_password_user).change_password_hash}
    assert_response :success
    assert_select '#error_body', false
    assert_template 'users/edit_password'

    assert_difference 'OldPassword.count' do
      patch :update_password, {
        :id => users(:blank_password_user).to_param,
        :user => {
          :password => 'new_password_123',
          :password_confirmation => 'new_password_123'
        },
        :confirmation_hash => users(:blank_password_user).change_password_hash
      }
    end

    user = User.find(users(:blank_password_user).id)
    assert_redirected_to login_url
    assert_equal User.digest('new_password_123', user.salt), user.password
    assert_not_nil user.last_access
    assert_equal 0, user.failed_attempts

    # No se puede usar 2 veces el mismo hash
    get :edit_password, {:id => users(:blank_password_user).to_param,
      :confirmation_hash => users(:blank_password_user).change_password_hash}
    assert_redirected_to login_url
  end

  test 'change expired blank password' do
    patch :update_password, {
      :id => users(:expired_blank_password_user).to_param,
      :user => {
        :password => 'new_password_123',
        :password_confirmation => 'new_password_123'
      },
      :confirmation_hash =>
        users(:expired_blank_password_user).change_password_hash
    }


    user = User.find(users(:expired_blank_password_user).id)
    assert_redirected_to login_url
    assert_not_equal User.digest('new_password_123', user.salt), user.password
  end

  test 'new initial' do
    get :new_initial, :hash => groups(:main_group).admin_hash
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/new_initial'
  end

  test 'new initial with invalid hash' do
    get :new_initial, :hash => "#{groups(:main_group).admin_hash}x"
    assert_redirected_to login_url
    assert_equal I18n.t('message.must_be_authenticated'), flash.alert
  end

  test 'create initial' do
    assert_difference ['User.count', 'OrganizationRole.count'] do
      post :create_initial, {
        :hash => groups(:main_group).admin_hash,
        :user => {
          :user => 'new_user_2',
          :name => 'New Name2',
          :last_name => 'New Last Name2',
          :email => 'new_user2@newemail.net',
          :language => I18n.available_locales.last.to_s,
          :resource_id => resources(:auditor_resource).id,
          :manager_id => users(:administrator_user).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => false,
          :organization_roles_attributes => [
            {
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          ]
        }
      }
    end

    assert_redirected_to login_url
    assert_equal I18n.t('user.correctly_created'), flash.notice
  end

  test 'create initial with invalid hash' do
    assert_no_difference ['User.count', 'OrganizationRole.count'] do
      post :create_initial, {
        :hash => "#{groups(:main_group).admin_hash}x",
        :user => {
          :user => 'new_user_2',
          :name => 'New Name2',
          :last_name => 'New Last Name2',
          :email => 'new_user2@newemail.net',
          :language => I18n.available_locales.last.to_s,
          :resource_id => resources(:auditor_resource).id,
          :manager_id => users(:administrator_user).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => false,
          :organization_roles_attributes => [
            {
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          ]
        }
      }
    end

    assert_redirected_to login_url
    assert_equal I18n.t('message.must_be_authenticated'), flash.alert
  end

  test 'get initial roles' do
    perform_auth
    xhr :get, :initial_roles, :id => organizations(:default_organization).id,
      :format => 'json', :hash => groups(:main_group).admin_hash
    assert_response :success
    roles = ActiveSupport::JSON.decode(@response.body)
    assert !roles.empty?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'get initial roles with invalid hash' do
    perform_auth
    xhr :get, :initial_roles, :id => organizations(:default_organization).id,
      :format => 'json', :hash => "#{groups(:main_group).admin_hash}x"

    assert_redirected_to login_url
    assert_equal I18n.t('message.must_be_authenticated'), flash.alert
  end

  test 'edit personal data' do
    perform_auth
    get :edit_personal_data, {:id => users(:administrator_user).user}
    assert_response :success
    assert_not_nil assigns(:auth_user)
    assert_select '#error_body', false
    assert_template 'users/edit_personal_data'
  end

  test 'update personal data' do
    assert_no_difference 'User.count' do
      perform_auth
      patch :update_personal_data, {
        :id => users(:administrator_user).to_param,
        :user => {
          :name => 'Updated Name',
          :last_name => 'Updated Last Name',
          :language => 'es',
          :email => 'updated@email.com'
        }
      }
    end

    assert_response :success
    assert_not_nil assigns(:auth_user)
    assert_equal 'Updated Name', assigns(:auth_user).name
    assert_select '#error_body', false
    assert_template 'users/edit_personal_data'
  end

  test 'user findings reassignment edit' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :reassignment_edit, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/reassignment_edit'
  end

  test 'user finding reassignment update' do
    perform_auth users(:administrator_user),
      organizations(:default_organization)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        patch :reassignment_update, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:audited_second_user).id,
            :with_findings => '1'
          }
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_reassignment_completed'), flash.notice
  end

  test 'user reviews reassignment edit' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :reassignment_edit, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/reassignment_edit'
  end

  test 'user reviews reassignment update' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        patch :reassignment_update, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:audited_second_user).id,
            :with_reviews => '1'
          }
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_reassignment_completed'), flash.notice
  end

  test 'user reassignment of nothing edit' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :reassignment_edit, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/reassignment_edit'
  end

  test 'user reassignment of nothing' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'Notification.count' do
        patch :reassignment_update, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:administrator_second_user).id
          }
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_reassignment_completed'), flash.notice
  end

  test 'user findings release edit' do
    perform_auth
    get :release_edit, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/release_edit'
  end

  test 'user findings release update' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :release_update, {
        :id => users(:auditor_user).user,
        :user => { :with_findings => '1' }
      }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_release_completed'), flash.notice
  end

  test 'user reviews release edit' do
    perform_auth
    get :release_edit, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/release_edit'
  end

  test 'user reviews release update' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :release_update, {
        :id => users(:auditor_user).user,
        :user => { :with_reviews => '1' }
      }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_release_completed'), flash.notice
  end

  test 'user release edit of nothing' do
    perform_auth
    get :release_edit, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/release_edit'
  end

  test 'user release update of nothing' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :release_update, {
        :id => users(:auditor_user).user,
        :user => {}
      }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('user.user_release_completed'), flash.notice
  end

  test 'export to pdf' do
    perform_auth

    assert_nothing_raised(Exception) { get :export_to_pdf }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('user.pdf.pdf_name'), User.table_name)
  end

  test 'export with search' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :search => {
        :query => 'manager',
        :columns => ['user', 'name']
      }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('user.pdf.pdf_name'), User.table_name)
  end

  test 'get roles' do
    perform_auth
    xhr :get, :roles, {:id => organizations(:default_organization).id,
      :format => 'json'}
    assert_response :success
    roles = ActiveSupport::JSON.decode(@response.body)
    assert !roles.empty?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'show user status' do
    perform_auth
    get :user_status, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/user_status'
  end

  test 'show user status without graph' do
    perform_auth
    get :user_status_without_graph, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/user_status_without_graph'
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :q => 'admin', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Administrator
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :auto_complete_for_user, { :q => 'blank', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size # Blank and Expired blank
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }

    post :auto_complete_for_user, { :q => 'xyz', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end
end
