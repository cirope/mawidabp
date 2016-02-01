require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'list organizations' do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
    assert 1, assigns(:organizations).map(&:group_id).uniq.size
  end

  test 'show organization' do
    get :show, id: organizations(:cirope)
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'new organization' do
    get :new
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'create organization' do
    assert_difference ['Organization.count', 'ImageModel.count'] do
      post :create, {
        organization: {
          name: 'New organization',
          prefix: 'new-prefix',
          description: 'New description',
          group_id: groups(:main_group).id,
          image_model_attributes: {
            image: Rack::Test::UploadedFile.new(
              "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
            )
          }
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'create organization with LDAP config' do
    assert_difference ['Organization.count', 'LdapConfig.count'] do
      post :create, {
        organization: {
          name: 'New organization',
          prefix: 'new-prefix',
          description: 'New description',
          group_id: groups(:main_group).id,
          ldap_config_attributes: {
            hostname: 'localhost',
            port: ENV['TRAVIS'] ? 3389 : 389,
            basedn: 'ou=people,dc=test,dc=com',
            filter: 'CN=*',
            login_mask: 'cn=%{user},%{basedn}',
            username_attribute: 'cn',
            name_attribute: 'givenname',
            last_name_attribute: 'sn',
            email_attribute: 'mail',
            function_attribute: 'title',
            roles_attribute: 'description',
            manager_attribute: 'manager',
            test_user: 'admin',
            test_password: 'admin123'
          }
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'create organization with wrong group' do
    assert_difference 'Organization.count' do
      post :create, {
        organization: {
          name: 'New organization',
          prefix: 'new-prefix',
          description: 'New description',
          group_id: groups(:second_group).id
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'edit organization' do
    get :edit, id: organizations(:cirope)
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'update organization' do
    patch :update, {
      id: organizations(:cirope),
      organization: {
        name: 'Updated organization',
        description: 'Updated description',
        image_model_attributes: {
          image: Rack::Test::UploadedFile.new(
            "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
          )
        }
      }
    }

    assert_redirected_to organizations_url
  end

  test 'destroy organization' do
    organization = organizations :google

    login user: users(:administrator_second_user), prefix: organization.prefix

    assert_difference ['Organization.count', 'BusinessUnitType.count'], -1 do
      delete :destroy, id: organization
    end

    assert_redirected_to organizations_url
  end
end
