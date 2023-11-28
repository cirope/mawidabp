require 'test_helper'
require 'minitest/mock'

class SamlSessionsControllerTest < ActionController::TestCase
  setup do
    @external_saml_url = 'https://login.saml/saml2'
    @organization      = organizations :cirope
  end

  test 'should get metadata' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      get :metadata

      assert_response :success
    end
  end

  test 'should create user with roles and redirect to welcome' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      'new_user@azure.com',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    ['SUPERVISOR']

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_difference ['User.count', 'OrganizationRole.count', 'LoginRecord.count'] do
          post :create

          provider  = @organization.saml_provider
          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal last_user.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
          assert_equal last_user.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert_equal last_user.organization_roles.first.role, roles(:supervisor_role)
          assert flash[:notice].blank?
          assert_redirected_to welcome_url
        end
      end
    end
  end

  test 'should create user with default roles and redirect to welcome' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    default_role_for_user                              = roles :auditor_role
    @organization.saml_provider.default_role_for_users = default_role_for_user

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      'new_user@azure.com',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_difference ['User.count', 'LoginRecord.count', 'OrganizationRole.count'] do
          post :create

          provider  = @organization.saml_provider
          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal last_user.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
          assert_equal last_user.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert last_user.enable
          assert_equal default_role_for_user, last_user.organization_roles.where(organization: @organization).take!.role
          assert flash[:notice].blank?
          assert_redirected_to welcome_url
        end
      end
    end
  end

  test 'should not create user when dont have DEFAULT_SAML_ROLES' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      'new_user@azure.com',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count', 'LoginRecord.count'] do
          assert_difference ['ErrorRecord.count'] do
            post :create

            assert_equal flash[:alert], I18n.t('message.invalid_user_or_password')
            assert_redirected_to login_url(saml_error: true)
          end
        end
      end
    end
  end

  #same in update
  test 'should raise exception when have blank attribute in response' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      '',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    ['SUPERVISOR']

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_raise ActiveRecord::RecordInvalid do
          post :create
        end
      end
    end
  end

  #same in update
  test 'should not create user when saml_response is invalid' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      'new_user@azure.com',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, false

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count', 'LoginRecord.count'] do
          assert_difference ['ErrorRecord.count'] do
            post :create

            assert_equal flash[:alert], I18n.t('message.invalid_user_or_password')
            assert_redirected_to login_url(saml_error: true)
          end
        end
      end
    end
  end

  test 'should update user with roles and redirect to welcome' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    user_to_update  = users :disabled
    user_to_update.update_saml_request_id '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      user_to_update.email,
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    ['SUPERVISOR']

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count'] do
          assert_difference 'LoginRecord.count' do
            post :create

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
            assert flash[:notice].blank?
            assert_redirected_to welcome_url
          end
        end
      end
    end
  end

  test 'should update user with roles and redirect to poll' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    user_to_update  = users :poll
    user_to_update.update_saml_request_id '91dfe9376a2e8e09e6dcb444c04fc53a'

    hash_attributes = get_hash_attributes name:      "#{user_to_update.user}@test.com",
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    ['SUPERVISOR']

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count'] do
          assert_difference 'LoginRecord.count' do
            post :create

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
            assert_equal flash[:notice], I18n.t('polls.has_unanswered', count: user_to_update.list_unanswered_polls.count)

            poll = user_to_update.list_unanswered_polls.first

            assert_redirected_to edit_poll_url(poll, token: poll.access_token)
          end
        end
      end
    end
  end

  test 'should update user with default roles and redirect to welcome' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    default_role_for_user                              = roles :auditor_role
    @organization.saml_provider.default_role_for_users = default_role_for_user

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    user_to_update = users :disabled
    user_to_update.update_saml_request_id '91dfe9376a2e8e09e6dcb444c04fc53a'

    organization_roles(:admin_role_for_disabled_in_cirope).destroy!

    hash_attributes = get_hash_attributes name:      user_to_update.email,
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference ['LoginRecord.count', 'OrganizationRole.count'] do
            post :create

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal default_role_for_user, user_to_update.organization_roles.where(organization: @organization).take!.role
            assert flash[:notice].blank?
            assert_redirected_to welcome_url
          end
        end
      end
    end
  end

  test 'should update user with default roles and redirect to poll' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    default_role_for_user                              = roles :auditor_role
    @organization.saml_provider.default_role_for_users = default_role_for_user

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    user_to_update = users :poll
    user_to_update.update_saml_request_id '91dfe9376a2e8e09e6dcb444c04fc53a'

    organization_roles(:auditor_role_for_poll_in_cirope).destroy!

    hash_attributes = get_hash_attributes name:      "#{user_to_update.user}@test.com",
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference ['LoginRecord.count', 'OrganizationRole.count'] do
            post :create

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal default_role_for_user, user_to_update.organization_roles.where(organization: @organization).take!.role
            assert_equal flash[:notice], I18n.t('polls.has_unanswered',count: user_to_update.list_unanswered_polls.count)

            poll = user_to_update.list_unanswered_polls.first

            assert_redirected_to edit_poll_url(poll, token: poll.access_token)
          end
        end
      end
    end
  end

  test 'should not update user because dont have roles and redirect to login' do
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'
    mock.expect :in_response_to, '91dfe9376a2e8e09e6dcb444c04fc53a'

    user_to_update   = users :administrator
    user_to_update.update_saml_request_id '91dfe9376a2e8e09e6dcb444c04fc53a'

    roles_to_destroy = user_to_update.organization_roles.where(organization: @organization).count
    hash_attributes  = get_hash_attributes name:      "#{user_to_update.user}@test.com",
                                           givenname: 'updated_name',
                                           surname:   'updated_surname',
                                           groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'LoginRecord.count'] do
          assert_difference 'OrganizationRole.count', (roles_to_destroy * -1) do
            assert_difference 'ErrorRecord.count' do
              post :create

              assert_equal flash[:alert], I18n.t('message.invalid_user_or_password')
              assert_redirected_to login_url(saml_error: true)
            end
          end
        end
      end
    end
  end

  private

    def get_hash_attributes name: nil, givenname: nil, surname: nil, groups: []
      {
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => name,
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => givenname,
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => surname,
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => groups
      }
    end

    def create_saml_provider organization
      new_saml_provider = SamlProvider.new provider: 'azure',
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
                                           organization: organization

      new_saml_provider.save!
    end
end
