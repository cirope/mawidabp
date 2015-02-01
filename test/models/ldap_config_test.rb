require 'test_helper'

class LdapConfigTest < ActiveSupport::TestCase
  setup do
    @ldap_config = ldap_configs :google_ldap
  end

  test 'validates presence' do
    @ldap_config.hostname = ''
    @ldap_config.port = nil
    @ldap_config.basedn = ''
    @ldap_config.username_ldap_attribute = ''
    @ldap_config.organization = nil

    assert @ldap_config.invalid?
    assert_error @ldap_config, :hostname, :blank
    assert_error @ldap_config, :port, :blank
    assert_error @ldap_config, :basedn, :blank
    assert_error @ldap_config, :username_ldap_attribute, :blank
    assert_error @ldap_config, :organization, :blank
  end

  test 'validates formats' do
    @ldap_config.port = 'xx'
    @ldap_config.basedn = 'dc=name,noway'
    @ldap_config.username_ldap_attribute = '?'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :not_a_number
    assert_error @ldap_config, :basedn, :invalid
    assert_error @ldap_config, :username_ldap_attribute, :invalid
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
end
