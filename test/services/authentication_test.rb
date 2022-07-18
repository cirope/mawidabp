require 'test_helper'
require 'minitest/mock'

class AuthenticationTest < ActionController::TestCase
  setup do
    @user = users :administrator
    @organization = organizations :cirope
    @params = { user: @user.user, password: 'admin123' }
    Current.organization = @organization
  end

  test 'should authenticate' do
    assert_valid_authentication redirect_url: Group, admin_mode: true
    assert_valid_authentication
  end

  test 'should authenticate via ldap' do
    @organization = organizations :google
    @params = { user: @user.user, password: 'admin123' }
    Current.organization = @organization

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
      @auth = Authentication.new @params, request, session, @organization, false
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
    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    Current.group = @organization.group

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => 'new_user@azure.com',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'new_user_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'new_user_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => ['SUPERVISOR']
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_difference ['User.count', 'OrganizationRole.count'], 1 do
          assert_valid_authentication

          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
          assert_equal last_user.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
          assert_equal last_user.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
          assert last_user.enable
          assert_equal last_user.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end
  end

  test 'should create user with default roles and redirect to welcome - saml authentication' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    Current.group = @organization.group

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: @organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => 'new_user@azure.com',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'new_user_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'new_user_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    default_roles = Role.where(organization: @organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_difference 'User.count' do
          assert_difference 'OrganizationRole.count', default_roles.count do
            assert_valid_authentication

            last_user = User.last

            assert_equal last_user.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
            assert_equal last_user.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal last_user.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
            assert_equal last_user.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
            assert last_user.enable

            new_user_roles = last_user.organization_roles.where(organization: @organization).map {|o_r| o_r.role}.sort_by(&:id)

            assert_equal default_roles, new_user_roles
          end
        end
      end
    end
  end

  test 'should not create user when dont have DEFAULT_SAML_ROLES - saml authentication' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.blank?

    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => 'new_user@azure.com',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'new_user_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'new_user_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

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
    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => '',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'new_user_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'new_user_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => ['SUPERVISOR']
    }

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
    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => 'new_user@azure.com',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'new_user_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'new_user_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

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
    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :disabled

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => user_to_update.email,
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'updated_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'updated_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => ['SUPERVISOR']
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count'] do
          assert_valid_authentication

          user_to_update.reload

          assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
          assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
          assert user_to_update.enable
          assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end
  end

  test 'should update user with roles and redirect to poll - saml authentication' do
    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :poll

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => "#{user_to_update.user}@test.com",
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'updated_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'updated_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => ['SUPERVISOR']
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference ['User.count', 'OrganizationRole.count'] do
          poll = user_to_update.list_unanswered_polls.first

          assert_valid_authentication redirect_url: [:edit, poll, token: poll.access_token], message: ['polls.has_unanswered', { count: user_to_update.list_unanswered_polls.count }]

          user_to_update.reload

          assert_equal user_to_update.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
          assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
          assert_equal user_to_update.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
          assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
          assert user_to_update.enable
          assert_equal user_to_update.organization_roles.first.role, roles(:supervisor_role)
        end
      end
    end
  end

  test 'should update user with default roles and redirect to welcome - saml authentication' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: @organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :disabled

    organization_roles(:admin_role_for_disabled_in_cirope).destroy!

    default_roles = Role.where(organization: @organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => user_to_update.email,
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'updated_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'updated_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference 'OrganizationRole.count', default_roles.count do
            assert_valid_authentication

            user_to_update.reload

            assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
            assert user_to_update.enable

            new_user_roles = user_to_update.organization_roles.where(organization: @organization).map {|o_r| o_r.role}.sort_by(&:id)

            assert_equal default_roles, new_user_roles
          end
        end
      end
    end
  end

  test 'should update user with default roles and redirect to poll - saml authentication' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: @organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :poll

    organization_roles(:auditor_role_for_poll_in_cirope).destroy!

    default_roles = Role.where(organization: @organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => "#{user_to_update.user}@test.com",
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'updated_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'updated_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference 'OrganizationRole.count', default_roles.count do
            poll = user_to_update.list_unanswered_polls.first

            assert_valid_authentication redirect_url: [:edit, poll, token: poll.access_token], message: ['polls.has_unanswered', { count: user_to_update.list_unanswered_polls.count }]

            user_to_update.reload

            assert_equal user_to_update.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
            assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal user_to_update.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
            assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
            assert user_to_update.enable

            new_user_roles = user_to_update.organization_roles.where(organization: @organization).map {|o_r| o_r.role}.sort_by(&:id)

            assert_equal default_roles, new_user_roles
          end
        end
      end
    end
  end

  test 'should not update user because dont have roles and redirect to login - saml authentication' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.blank?

    @organization = organizations :cirope
    @organization.saml_provider = 'azure'

    @organization.save!

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: 'https://login.saml/saml2' })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :administrator

    roles_to_destroy = user_to_update.organization_roles.where(organization: @organization).count

    hash_attributes = {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => "#{user_to_update.user}@test.com",
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => 'updated_name',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => 'updated_surname',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups' => []
    }

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
      @auth = Authentication.new @params, request, session, @organization, admin_mode

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
      @auth = Authentication.new @params, request, session, @organization, admin_mode

      assert_difference 'ErrorRecord.count' do
        assert !@auth.authenticated?
        assert_equal redirect_url || Hash[controller: 'sessions', action: 'new'], @auth.redirect_url
        assert_equal I18n.t(*message || 'message.invalid_user_or_password'), @auth.message
        assert_kind_of ErrorRecord, error_record(:on_login)
      end
    end

    def error_record error_type
      ErrorRecord.where(user: @user, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end
end
