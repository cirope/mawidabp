require 'test_helper'

# Pruebas para el controlador de usuarios
class UsersControllerTest < ActionController::TestCase
  def setup
    @request.host = "#{organizations(:cirope).prefix}.localhost.i"
  end

  test 'list users' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_template 'users/index'
  end

  test 'list users with search' do
    login
    get :index, :search => {:query => 'manager', :columns => ['user', 'name']}
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 5, assigns(:users).count
    assert_template 'users/index'
  end


  test 'edit user when search match only one result' do
    login
    get :index, :search => {:query => 'admin', :columns => ['user', 'name']}
    assert_redirected_to user_url(users(:administrator_user))
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).count
  end

  test 'show user' do
    login
    get :show, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_template 'users/show'
  end

  test 'new user' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert_template 'users/new'
  end

  test 'create user' do
    login
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
              :organization_id => organizations(:cirope).id,
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
                :organization_id => organizations(:cirope).id,
                :role_id => roles(:admin_role).id
              }
            ]
          }
        }
      end
    end
  end

  test 'edit user' do
    login
    get :edit, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_template 'users/edit'
  end

  test 'update user' do
    login

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
              :id => organization_roles(:admin_role_for_administrator_user_in_cirope).id,
              :organization_id => organizations(:cirope).id,
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
    login

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
                  :organization_id => organizations(:cirope).id,
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
    login
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
    login
    assert_no_difference 'User.count' do
      delete :destroy, :id => users(:audited_user).user
    end

    assert_equal I18n.t('user.will_be_orphan_findings'), flash.alert
    assert_redirected_to users_url
  end

  test 'new initial' do
    get :new_initial, :hash => groups(:main_group).admin_hash
    assert_response :success
    assert_not_nil assigns(:user)
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
              :organization_id => organizations(:cirope).id,
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
              :organization_id => organizations(:cirope).id,
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
    login
    xhr :get, :initial_roles, :id => organizations(:cirope).id,
      :format => 'json', :hash => groups(:main_group).admin_hash
    assert_response :success
    roles = ActiveSupport::JSON.decode(@response.body)
    assert !roles.empty?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'get initial roles with invalid hash' do
    login
    xhr :get, :initial_roles, :id => organizations(:cirope).id,
      :format => 'json', :hash => "#{groups(:main_group).admin_hash}x"

    assert_redirected_to login_url
    assert_equal I18n.t('message.must_be_authenticated'), flash.alert
  end

  test 'export to pdf' do
    login

    assert_nothing_raised { get :export_to_pdf }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('user.pdf.pdf_name'), User.table_name)
  end

  test 'export with search' do
    login

    assert_nothing_raised do
      get :export_to_pdf, :search => {
        :query => 'manager',
        :columns => ['user', 'name']
      }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('user.pdf.pdf_name'), User.table_name)
  end

  test 'get roles' do
    login
    xhr :get, :roles, {:id => organizations(:cirope).id,
      :format => 'json'}
    assert_response :success
    roles = ActiveSupport::JSON.decode(@response.body)
    assert !roles.empty?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'auto complete for user' do
    login
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
