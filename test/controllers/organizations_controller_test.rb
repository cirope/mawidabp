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
    get :show, params: { id: organizations(:cirope) }
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'new organization' do
    get :new
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'create organization' do
    assert_difference 'ImageModel.count', 2 do
      assert_difference 'Organization.count' do
        post :create, params: {
          organization: {
            name: 'New organization',
            prefix: 'new-prefix',
            description: 'New description',
            group_id: groups(:main_group).id,
            image_model_attributes: {
              image: Rack::Test::UploadedFile.new(
                "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
              )
            },
            co_brand_image_model_attributes: {
              image: Rack::Test::UploadedFile.new(
                "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
              )
            }
          }
        }
      end
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'create organization with saml_provider' do
    assert_difference ['Organization.count', 'SamlProvider.count'] do
      post :create, params: {
        organization: {
          name:        'New organization',
          prefix:      'new-prefix',
          description: 'New description',
          group_id:    groups(:main_group).id,
          saml_provider_attributes: {
            provider: 'azure',
            idp_homepage: 'https://login.microsoftonline.com/test/federationmetadata/2007-06/federationmetadata.xml',
            idp_entity_id: 'https://sts.windows.net/test/',
            idp_sso_target_url: 'https://login.microsoftonline.com/test/saml2',
            sp_entity_id: 'https://test.com/saml/metadata',
            assertion_consumer_service_url: 'https://test.com/saml/callback',
            name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
            assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
            idp_cert: 'cert_test',
            username_claim: 'name',
            name_claim: 'givenname',
            lastname_claim: 'surname',
            email_claim: 'name',
            roles_claim: 'groups',
          }
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'create organization with LDAP config' do
    assert_difference ['Organization.count', 'LdapConfig.count'] do
      post :create, params: {
        organization: {
          name:                   'New organization',
          prefix:                 'new-prefix',
          description:            'New description',
          group_id:               groups(:main_group).id,
          ldap_config_attributes: {
            hostname:             'localhost',
            port:                 ldap_port,
            basedn:               'ou=people,dc=test,dc=com',
            filter:               'CN=*',
            login_mask:           'cn=%{user},%{basedn}',
            username_attribute:   'cn',
            name_attribute:       'givenname',
            last_name_attribute:  'sn',
            email_attribute:      'mail',
            function_attribute:   'title',
            office_attribute:     'postofficebox',
            roles_attribute:      'description',
            manager_attribute:    'manager',
            test_user:            'admin',
            test_password:        'admin123',
            alternative_hostname: '127.0.0.1',
            alternative_port:     ldap_port
          }
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
  end

  test 'create organization with LDAP config and service user' do
    assert_difference ['Organization.count', 'LdapConfig.count'] do
      post :create, params: {
        organization: {
          name: 'New organization',
          prefix: 'new-prefix',
          description: 'New description',
          group_id: groups(:main_group).id,
          ldap_config_attributes: {
            hostname: 'localhost',
            port: ENV['GH_ACTIONS'] ? 3389 : 389,
            basedn: 'ou=people,dc=test,dc=com',
            filter: 'CN=*',
            login_mask: 'cn=%{user},%{basedn}',
            username_attribute: 'cn',
            name_attribute: 'givenname',
            last_name_attribute: 'sn',
            email_attribute: 'mail',
            function_attribute: 'title',
            office_attribute: 'postofficebox',
            roles_attribute: 'description',
            manager_attribute: 'manager',
            user: 'admin',
            password: 'admin123'
          }
        }
      }
    end

    assert_equal groups(:main_group).id, assigns(:organization).reload.group_id
    assert_equal 'admin', assigns(:organization).ldap_config.user
  end

  test 'create organization with wrong group' do
    assert_difference 'Organization.count' do
      post :create, params: {
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
    get :edit, params: { id: organizations(:cirope) }
    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test 'update organization' do
    patch :update, params: {
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

    login user: users(:administrator_second), prefix: organization.prefix

    assert_difference ['Organization.count', 'BusinessUnitType.count'], -1 do
      delete :destroy, params: { id: organization }
    end

    assert_redirected_to organizations_url
  end
end
