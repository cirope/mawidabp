require 'test_helper'
require 'minitest/mock'

class SamlSessionsControllerTest < ActionController::TestCase
  setup do
    @external_saml_url = 'https://login.saml/saml2'
  end

  test 'should redirect to new_session_url when saml_config nil' do
    IdpSettingsAdapter.stub :saml_settings, nil do
      get :new

      assert_redirected_to login_url
    end
  end

  test 'should redirect to login azure' do
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      mock = Minitest::Mock.new

      mock.expect :create, @external_saml_url, [response_stub]

      OneLogin::RubySaml::Authrequest.stub :new, mock do
        get :new

        assert_redirected_to @external_saml_url
      end
    end
  end

  test 'should get metadata' do
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      get :metadata

      assert_response :success
    end
  end

  test 'should create user with roles and redirect to welcome' do
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

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

          last_user = User.last

          assert_equal last_user.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
          assert_equal last_user.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
          assert_equal last_user.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
          assert_equal last_user.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
          assert last_user.enable
          assert_equal last_user.organization_roles.first.role, roles(:supervisor_role)
          assert flash[:notice].blank?
          assert_redirected_to welcome_url
        end
      end
    end
  end

  test 'should create user with default roles and redirect to welcome' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    hash_attributes = get_hash_attributes name:      'new_user@azure.com',
                                          givenname: 'new_user_name',
                                          surname:   'new_user_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    default_roles = Role.where(organization: organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_difference ['User.count', 'LoginRecord.count'] do
          assert_difference 'OrganizationRole.count', default_roles.count do
            post :create

            last_user = User.last

            assert_equal last_user.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
            assert_equal last_user.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal last_user.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
            assert_equal last_user.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
            assert last_user.enable

            new_user_roles = last_user.organization_roles.where(organization: organization).map {|o_r| o_r.role}.sort_by(&:id)

            assert_equal default_roles, new_user_roles
            assert flash[:notice].blank?
            assert_redirected_to welcome_url
          end
        end
      end
    end
  end

  test 'should not create user when dont have DEFAULT_SAML_ROLES' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.blank?

    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

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
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

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
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

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
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update  = users :disabled
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

            user_to_update.reload

            assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
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
    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update  = users :poll
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

            user_to_update.reload

            assert_equal user_to_update.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
            assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
            assert_equal user_to_update.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
            assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
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
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :disabled

    organization_roles(:admin_role_for_disabled_in_cirope).destroy!

    default_roles   = Role.where(organization: organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a
    hash_attributes = get_hash_attributes name:      user_to_update.email,
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference 'LoginRecord.count' do
            assert_difference 'OrganizationRole.count', default_roles.count do
              post :create

              user_to_update.reload

              assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
              assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
              assert user_to_update.enable

              new_user_roles = user_to_update.organization_roles.where(organization: organization).map {|o_r| o_r.role}.sort_by(&:id)

              assert_equal default_roles, new_user_roles
              assert flash[:notice].blank?
              assert_redirected_to welcome_url
            end
          end
        end
      end
    end
  end

  test 'should update user with default roles and redirect to poll' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.present?

    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    DEFAULT_SAML_ROLES.each do |role_name|
      new_role = Role.new name: role_name,
                          organization: organization

      new_role.inject_auth_privileges(Hash.new(Hash.new(true)))

      new_role.save!
    end

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update = users :poll

    organization_roles(:auditor_role_for_poll_in_cirope).destroy!

    default_roles   = Role.where(organization: organization, name: DEFAULT_SAML_ROLES).sort_by(&:id).to_a
    hash_attributes = get_hash_attributes name:      "#{user_to_update.user}@test.com",
                                          givenname: 'updated_name',
                                          surname:   'updated_surname',
                                          groups:    []

    mock.expect :attributes, hash_attributes
    mock.expect :is_valid?, true

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      OneLogin::RubySaml::Response.stub :new, mock do
        assert_no_difference 'User.count' do
          assert_difference 'LoginRecord.count' do
            assert_difference 'OrganizationRole.count', default_roles.count do
              post :create

              user_to_update.reload

              assert_equal user_to_update.user, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, '')
              assert_equal user_to_update.name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first
              assert_equal user_to_update.email, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first
              assert_equal user_to_update.last_name, Array(hash_attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first
              assert user_to_update.enable

              new_user_roles = user_to_update.organization_roles.where(organization: organization).map {|o_r| o_r.role}.sort_by(&:id)

              assert_equal default_roles, new_user_roles
              assert_equal flash[:notice], I18n.t('polls.has_unanswered',count: user_to_update.list_unanswered_polls.count)

              poll = user_to_update.list_unanswered_polls.first

              assert_redirected_to edit_poll_url(poll, token: poll.access_token)
            end
          end
        end
      end
    end
  end

  test 'should not update user because dont have roles and redirect to login' do
    skip unless USE_SCOPE_CYCLE && DEFAULT_SAML_ROLES.blank?

    organization               = organizations :cirope
    organization.saml_provider = 'azure'

    organization.save!

    set_host_for_organization organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    mock = Minitest::Mock.new

    mock.expect :nameid, 'email'

    user_to_update   = users :administrator
    roles_to_destroy = user_to_update.organization_roles.where(organization: organization).count
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
end
