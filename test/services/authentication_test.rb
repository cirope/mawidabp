require 'test_helper'
require 'minitest/mock'

class AuthenticationTest < ActionController::TestCase
  setup do
    @user                = users :administrator
    @organization        = organizations :cirope
    @params              = { user: @user.user, password: 'admin123' }
    @external_saml_url   = 'https://login.saml/saml2'
    Current.organization = @organization
  end

  test 'should authenticate' do
    assert_valid_authentication redirect_url: Group, admin_mode: true
    assert_valid_authentication
  end

  test 'should authenticate by email' do
    @params = { email: @user.email, password: 'admin123' }

    assert_valid_authentication redirect_url: Group, admin_mode: true
  ensure
    @params = { user: @user.user, password: 'admin123' }
  end

  test 'should authenticate via ldap' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'admin123' }
    Current.organization = @organization

    assert_valid_authentication
  end

  test 'should authenticate with ldap config and recovery user' do
    tag = tags :recovery

    @organization = organizations :google
    @organization.ldap_config.update_column :hostname, 'wrong_hostname'

    @params = { user: @user.user, password: 'admin123' }

    Current.organization = @organization

    assert !@user.recovery?
    assert_invalid_authentication message: 'message.ldap_error'

    @user.taggings.create! tag: tag

    assert @user.recovery?
    assert_valid_authentication
  end

  test 'should authenticate with saml config and recovery user' do
    tag = tags :recovery

    @organization = organizations :google
    @organization.ldap_config.destroy!

    saml_provider = SamlProvider.create! provider: 'azure',
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
                                      organization: @organization

    @organization.reload
    @params = { user: @user.user, password: 'admin123', SAMLResponse: '' }

    Current.organization = @organization

    assert !@user.recovery?
    assert_invalid_authentication redirect_url: Hash[controller: 'sessions', action: 'new', saml_error: true]

    @user.taggings.create! tag: tag

    assert @user.recovery?
    assert_valid_authentication
  end

  test 'should authenticate via ldap using the proper config' do
    role = roles :admin_second_alphabet_role
    ldap_config = ldap_configs :google_ldap
    username = ldap_config.login_mask % { user: @user.user, basedn: ldap_config.basedn }
    @params = { user: username, password: 'admin123' }
    @organization = organizations :alphabet
    Current.organization = @organization

    @user.organization_roles.create! role_id: role.id, organization_id: role.organization_id

    assert_valid_authentication
  end

  test 'no group admin user attempt login in admin mode' do
    request.host = [APP_ADMIN_PREFIXES.first, URL_HOST].join('.')
    @user.update_column :group_admin, false

    assert_invalid_authentication admin_mode: true
  end

  test 'should show message days for password expiration' do
    password_changed = get_test_parameter(:expire_notification).to_i.next.days.ago
    @user.update_column :password_changed, password_changed

    days_for_password_expiration = @user.days_for_password_expiration
    message = [days_for_password_expiration >= 0 ?
      'message.password_expire_in_x' : 'message.password_expired_x_days_ago',
      count: days_for_password_expiration.abs]

    assert_valid_authentication message: message
  end

  test 'should show message must change the password' do
    @user.update_column :password_changed, get_test_parameter(:password_expire_time).to_i.next.days.ago

    assert_valid_authentication redirect_url: [:edit, :users_password, id: @user],
      message: 'message.must_change_the_password'
  end

  test 'should show message pending poll' do
    Poll.answered(false).first.update_column :user_id, @user.id

    poll = @user.first_pending_poll
    poll_redirect = [:edit, poll, token: poll.access_token]

    assert_valid_authentication redirect_url: poll_redirect,
      message: ['polls.has_unanswered', count: @user.list_unanswered_polls.count]
  end

  test 'should not login with invalid password' do
    @params = { user: @user.user, password: 'wrong password' }

    assert_invalid_authentication
    assert_invalid_authentication admin_mode: true
  end

  test 'should not authenticate via ldap with invalid password' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'wrong password' }
    Current.organization = @organization

    assert_invalid_authentication
  end

  test 'should show a message when ldap is not reacheble' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'wrong password' }
    Current.organization = @organization

    @organization.ldap_config.update port: 1

    assert_invalid_authentication message: 'message.ldap_error'
  end

  test 'should not login if user expired' do
    @user.update_column :last_access,
      get_test_parameter(:account_expire_time).to_i.days.ago.yesterday

    assert_invalid_authentication
    assert !@user.reload.enable?
  end

  test 'should not login user as disabled' do
    @user.update_column :enable, false

    assert_invalid_authentication
    assert_invalid_authentication admin_mode: true
  end

  test 'should not login user as hidden' do
    @user.update_column :hidden, true

    assert_invalid_authentication
  end

  test 'should not login with hashed password' do
    @params = { user: @user.user, password: @user.password }

    assert_invalid_authentication
  end

  test 'should not login concurrent users' do
    setting = @organization.settings.find_by name: 'allow_concurrent_sessions'
    setting.update_column :value, 0
    @user.update! last_access: 1.minute.ago, logged_in: true

    assert_invalid_authentication message: 'message.you_are_already_logged'
  end

  test 'excede maximun number off wrong attempts' do
    max_attempts =
      @user.get_parameter(:attempts_count, false, @organization.id).to_i
    @params = { user: @user.user, password: 'wrong password' }

    assert_difference 'ErrorRecord.count', max_attempts.next do
      max_attempts.pred.times { assert_invalid_authentication }
      @auth = Authentication.new @params, request, session, @organization, false, @user
      @auth.authenticated?
    end

    assert_kind_of ErrorRecord, error_record(:user_disabled)
    assert_equal max_attempts, @user.reload.failed_attempts
    assert !@user.enable?
  end

  test 'first login' do
    @user.update_column :last_access, nil

    assert_valid_authentication redirect_url: [:edit, :users_password, id: @user],
      message: 'message.must_change_the_password'

    login_record = LoginRecord.find_by user: @user, organization: @organization
    assert_kind_of LoginRecord, login_record
  end

  #authentication with saml

  test 'should create user with roles and redirect to welcome - saml authentication' do
    set_organization

    original_limit = Rails.application.credentials.auditors_limit

    Rails.application.credentials.auditors_limit = (
      Current.group.users.can_act_as(:auditor).reload.count + 1
    )

    create_saml_provider @organization

    Current.group = @organization.group

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
        assert_difference ['User.count', 'OrganizationRole.count'] do
          assert_valid_authentication

          provider  = @organization.saml_provider
          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal last_user.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
          assert_equal last_user.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert last_user.enable
          assert_equal last_user.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end

  ensure
    Rails.application.credentials.auditors_limit = original_limit
  end

  test 'should create user with default role and redirect to welcome - saml authentication' do
    set_organization

    original_limit = Rails.application.credentials.auditors_limit

    Rails.application.credentials.auditors_limit = (
      Current.group.users.can_act_as(:auditor).reload.count + 1
    )

    create_saml_provider @organization

    Current.group                                      = @organization.group
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
        assert_difference ['User.count', 'OrganizationRole.count'] do
          assert_valid_authentication

          provider  = @organization.saml_provider
          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal last_user.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
          assert_equal last_user.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert last_user.enable
          assert_equal default_role_for_user, last_user.organization_roles.where(organization: @organization).take!.role
        end
      end
    end

  ensure
    Rails.application.credentials.auditors_limit = original_limit
  end

  test 'should not create user when dont have default role - saml authentication' do
    create_saml_provider @organization

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
          assert_invalid_authentication redirect_url: Hash[controller: 'sessions', action: 'new', saml_error: true]
        end
      end
    end
  end

  #same in update
  test 'should raise exception when have blank attribute in response - saml authentication' do
    create_saml_provider @organization

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
          @auth = Authentication.new @params, request, session, @organization, false
        end
      end
    end
  end

  #same in update
  test 'should not create user when saml_response is invalid - saml authentication' do
    create_saml_provider @organization

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
          assert_invalid_authentication redirect_url: Hash[controller: 'sessions', action: 'new', saml_error: true]
        end
      end
    end
  end

  test 'should update user with roles and redirect to welcome - saml authentication' do
    set_organization

    create_saml_provider @organization

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
          assert_valid_authentication

          provider = @organization.saml_provider
          user_to_update.reload

          assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert user_to_update.enable
          assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end
  end

  test 'should update user with roles and redirect to poll - saml authentication' do
    create_saml_provider @organization

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
          poll = user_to_update.list_unanswered_polls.first

          assert_valid_authentication redirect_url: [:edit, poll, token: poll.access_token], message: ['polls.has_unanswered', { count: user_to_update.list_unanswered_polls.count }]

          provider = @organization.saml_provider
          user_to_update.reload

          assert_equal user_to_update.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
          assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
          assert_equal user_to_update.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
          assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
          assert user_to_update.enable
          assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end
  end

  test 'should update user with default role and redirect to welcome - saml authentication' do
    create_saml_provider @organization

    Current.group                                      = @organization.group
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
          assert_difference 'OrganizationRole.count' do
            assert_valid_authentication

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal default_role_for_user, user_to_update.organization_roles.where(organization: @organization).take!.role
          end
        end
      end
    end
  end

  test 'should update user with default role and redirect to poll - saml authentication' do
    create_saml_provider @organization

    Current.group                                      = @organization.group
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
          assert_difference 'OrganizationRole.count' do
            poll = user_to_update.list_unanswered_polls.first

            assert_valid_authentication redirect_url: [:edit, poll, token: poll.access_token], message: ['polls.has_unanswered', { count: user_to_update.list_unanswered_polls.count }]

            provider = @organization.saml_provider
            user_to_update.reload

            assert_equal user_to_update.user, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.username_claim}"]).first.to_s.sub(/@.+/, '')
            assert_equal user_to_update.name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.name_claim}"]).first
            assert_equal user_to_update.email, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.email_claim}"]).first
            assert_equal user_to_update.last_name, Array(hash_attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/#{provider.lastname_claim}"]).first
            assert user_to_update.enable
            assert_equal default_role_for_user, user_to_update.organization_roles.where(organization: @organization).take!.role
          end
        end
      end
    end
  end

  test 'should not update user because dont have roles and redirect to login - saml authentication' do
    create_saml_provider @organization

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
            assert_invalid_authentication redirect_url: Hash[controller: 'sessions', action: 'new', saml_error: true]
          end
        end
      end
    end
  end

  private

    def assert_valid_authentication redirect_url: nil, message: nil, admin_mode: false
      @auth = Authentication.new @params, request, session, @organization, admin_mode, @user

      assert_difference 'LoginRecord.count' do
        assert @auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'welcome', action: 'index'], @auth.redirect_url

        if message && message.respond_to?(:last) && message.last.is_a?(Hash)
          options = message.pop

          assert_equal I18n.t(*message, **options), @auth.message
        elsif message
          assert_equal I18n.t(*message), @auth.message
        else
          assert_nil @auth.message
        end
      end
    end

    def assert_invalid_authentication redirect_url: nil, message: nil, admin_mode: false
      @auth = Authentication.new @params, request, session, @organization, admin_mode, @user

      assert_difference 'ErrorRecord.count' do
        assert !@auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'authentications', action: 'new'], @auth.redirect_url
        assert_equal I18n.t(*message || 'message.invalid_user_or_password'), @auth.message
        assert_kind_of ErrorRecord, error_record(:on_login)
      end
    end

    def error_record error_type
      ErrorRecord.where(user: @user, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end

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
