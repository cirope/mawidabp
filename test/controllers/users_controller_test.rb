# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    login
  end

  test 'list users' do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'list users with search' do
    get :index, params: {
      search: {
        query: 'manager',
        columns: ['user', 'name']
      }
    }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 5, assigns(:users).count
  end

  test 'show user' do
    get :show, params: { id: users(:administrator) }
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'new user' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'can not get new when ldap' do
    skip if ENABLE_USER_CREATION_WHEN_LDAP

    login prefix: organizations(:google).prefix

    get :new
    assert_redirected_to login_url
  end

  test 'can get new when ldap and ENABLE_USER_CREATION_WHEN_LDAP' do
    skip unless ENABLE_USER_CREATION_WHEN_LDAP

    login prefix: organizations(:google).prefix

    get :new
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'create user' do
    counts_array = ['User.count', 'RelatedUserRelation.count', 'OrganizationRole.count']

    assert_enqueued_emails 1 do
      assert_difference counts_array do
        post :create, params: {
          user: {
            user:                          'new_user',
            name:                          'New Name',
            last_name:                     'New Last Name',
            email:                         'new_user@newemail.net',
            language:                      I18n.available_locales.last.to_s,
            notes:                         'Some user notes',
            manager_id:                    users(:administrator).id,
            logged_in:                     false,
            enable:                        true,
            send_notification_email:       '1',
            organization_roles_attributes: [
              {
                organization_id: organizations(:cirope).id,
                role_id:         roles(:executive_manager_role).id
              }
            ],
            related_user_relations_attributes: [
              { related_user_id: users(:plain_manager).id }
            ]
          }
        }
      end
    end

    clear_enqueued_jobs
    clear_performed_jobs

    assert_no_enqueued_emails do
      assert_difference ['User.count', 'OrganizationRole.count'] do
        post :create, params: {
          user: {
            user:                          'new_user_2',
            name:                          'New Name2',
            last_name:                     'New Last Name2',
            email:                         'new_user2@newemail.net',
            language:                      I18n.available_locales.last.to_s,
            notes:                         'Some user notes',
            manager_id:                    users(:administrator).id,
            logged_in:                     false,
            enable:                        true,
            send_notification_email:       '',
            organization_roles_attributes: [
              {
                organization_id: organizations(:cirope).id,
                role_id:         roles(:executive_manager_role).id
              }
            ]
          }
        }
      end
    end
  end

  test 'edit user' do
    get :edit, params: { id: users(:administrator) }
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'update user' do
    user = users :administrator
    counts_array = ['User.count', 'OrganizationRole.count', 'user.children.count']

    assert_no_emails do
      assert_no_difference counts_array do
        patch :update, params: {
          id: user,
          user: {
            user: 'updated_name',
            name: 'Updated Name',
            last_name: 'Updated Last Name',
            email: 'updated_user@updatedemail.net',
            notes: 'Updated user notes',
            language: I18n.available_locales.first.to_s,
            logged_in: false,
            enable: true,
            send_notification_email: '',
            organization_roles_attributes: [
              {
                id: organization_roles(:admin_role_for_administrator_in_cirope).id,
                organization_id: organizations(:cirope).id,
                role_id: roles(:admin_role).id
              }
            ],
            child_ids: [
              users(:administrator_second).id,
              users(:bare).id,
              users(:first_time).id,
              users(:expired).id,
              users(:disabled).id,
              users(:blank_password).id,
              users(:expired_blank_password).id,
              users(:supervisor).id,
              users(:supervisor_second).id,
              users(:committee).id
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
    user = users :administrator

    assert_no_difference ['User.count', 'user.children.count'] do
      assert_enqueued_emails 1 do
        assert_difference 'OrganizationRole.count' do
          patch :update, params: {
            id: users(:administrator),
            user: {
              user: 'updated_name_2',
              name: 'Updated Name',
              last_name: 'Updated Last Name',
              email: 'updated_user@updatedemail.net',
              language: I18n.available_locales.first.to_s,
              notes: 'Updated user notes',
              logged_in: false,
              enable: true,
              send_notification_email: '1',
              organization_roles_attributes: [
                {
                  organization_id: organizations(:google).id,
                  role_id: roles(:admin_second_role).id
                }
              ],
              child_ids: [
                users(:administrator_second).id,
                users(:bare).id,
                users(:first_time).id,
                users(:expired).id,
                users(:disabled).id,
                users(:blank_password).id,
                users(:expired_blank_password).id,
                users(:supervisor).id,
                users(:supervisor_second).id,
                # El siguiente se elimina
                users(:committee).id
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
    user = users :supervisor_second

    assert user.enable?
    assert user.findings.all_for_reallocation.empty?

    assert_no_difference 'User.count' do
      delete :destroy, params: { id: user }
    end

    assert !user.reload.enable?
    assert_redirected_to users_url
  end

  test 'disable audited user' do
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: users(:audited) }
    end

    assert_redirected_to users_url
  end

  test 'index as pdf' do
    get :index, as: :pdf

    Current.organization = organizations(:cirope)
    assert_redirected_to UserPdf.new.relative_path
  end

  test 'should download user list as csv' do
    get :index, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'export with search' do
    get :index, params: {
      search: {
        query: 'manager',
        columns: ['user', 'name']
      }
    }, as: :pdf

    Current.organization = organizations(:cirope)
    assert_redirected_to UserPdf.new.relative_path
  end

  test 'create user with left users count with registration' do
    skip unless ENABLE_PUBLIC_REGISTRATION

    set_organization

    original_limit = Rails.application.credentials.auditors_limit

    assert_difference 'User.count' do
      Rails.application.credentials.auditors_limit = (
        Current.group.users.can_act_as(:auditor).reload.count + 5
      )

      post :create, params: {
        user: {
          user:                          'new_user',
          name:                          'New Name',
          last_name:                     'New Last Name',
          email:                         'new_user@newemail.net',
          language:                      I18n.available_locales.last.to_s,
          notes:                         'Some user notes',
          enable:                        true,
          organization_roles_attributes: [
            {
              organization_id: Current.organization.id,
              role_id:         roles(:auditor_role).id
            }
          ]
        }
      }

      assert_redirected_to users_url
    end

    assert_equal I18n.t('users.create.correctly_created_with_count', count: 4), flash.notice

    Rails.application.credentials.auditors_limit = original_limit
  end

  test 'create user with left users count without registration' do
    skip if ENABLE_PUBLIC_REGISTRATION

    set_organization

    original_limit = Rails.application.credentials.auditors_limit

    assert_difference 'User.count' do
      Rails.application.credentials.auditors_limit = (
        User.can_act_as(:auditor).reload.count + 5
      )

      post :create, params: {
        user: {
          user:                          'new_user',
          name:                          'New Name',
          last_name:                     'New Last Name',
          email:                         'new_user@newemail.net',
          language:                      I18n.available_locales.last.to_s,
          notes:                         'Some user notes',
          enable:                        true,
          organization_roles_attributes: [
            {
              organization_id: Current.organization.id,
              role_id:         roles(:auditor_role).id
            }
          ]
        }
      }

      assert_redirected_to users_url
    end

    assert_equal I18n.t('users.create.correctly_created_with_count', count: 4), flash.notice

    Rails.application.credentials.auditors_limit = original_limit
  end
end
