require 'test_helper'

class LdapConfigTest < ActiveSupport::TestCase
  setup do
    @ldap_config = ldap_configs :google_ldap
  end

  test 'validates presence' do
    @ldap_config.hostname = ''
    @ldap_config.port = nil
    @ldap_config.basedn = ''
    @ldap_config.login_mask = ''
    @ldap_config.username_attribute = ''
    @ldap_config.name_attribute = ''
    @ldap_config.last_name_attribute = ''
    @ldap_config.email_attribute = ''
    @ldap_config.roles_attribute = ''
    @ldap_config.organization = nil

    assert @ldap_config.invalid?
    assert_error @ldap_config, :hostname, :blank
    assert_error @ldap_config, :port, :blank
    assert_error @ldap_config, :basedn, :blank
    assert_error @ldap_config, :login_mask, :blank
    assert_error @ldap_config, :username_attribute, :blank
    assert_error @ldap_config, :name_attribute, :blank
    assert_error @ldap_config, :last_name_attribute, :blank
    assert_error @ldap_config, :email_attribute, :blank
    assert_error @ldap_config, :roles_attribute, :blank
    assert_error @ldap_config, :organization, :blank
  end

  test 'validates formats' do
    @ldap_config.port = 'xx'
    @ldap_config.basedn = 'dc=name,noway'
    @ldap_config.username_attribute = '?'
    @ldap_config.name_attribute = '?'
    @ldap_config.last_name_attribute = '?'
    @ldap_config.email_attribute = '?'
    @ldap_config.function_attribute = '?'
    @ldap_config.roles_attribute = '?'
    @ldap_config.manager_attribute = '?'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :not_a_number
    assert_error @ldap_config, :basedn, :invalid
    assert_error @ldap_config, :username_attribute, :invalid
    assert_error @ldap_config, :name_attribute, :invalid
    assert_error @ldap_config, :last_name_attribute, :invalid
    assert_error @ldap_config, :email_attribute, :invalid
    assert_error @ldap_config, :function_attribute, :invalid
    assert_error @ldap_config, :roles_attribute, :invalid
    assert_error @ldap_config, :manager_attribute, :invalid
  end

  test 'validates port range' do
    @ldap_config.port = 0

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :greater_than, count: 0

    @ldap_config.port = 65536

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :less_than, count: 65536
  end

  test 'ldap bind' do
    ldap = @ldap_config.ldap 'admin', 'admin123'

    assert ldap.bind
  end

  test 'ldap no bind if wrong password' do
    ldap = @ldap_config.ldap 'admin', 'wrong'

    assert !ldap.bind
  end

  test 'import' do
    set_organization organizations(:google)

    user = users :administrator_user
    role = roles :admin_second_role

    assert user.organization_roles.map(&:role_id).exclude?(role.id)

    assert_difference 'User.count' do
      @ldap_config.import 'admin', 'admin123'
    end

    assert user.reload.organization_roles.map(&:role_id).include?(role.id)
    assert_equal user.id, User.find_by(user: 'new_user').manager_id
  end
end
