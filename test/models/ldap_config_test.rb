# frozen_string_literal: true

require 'test_helper'

class LdapConfigTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @ldap_config = ldap_configs :google_ldap
  end

  test 'validates presence' do
    @ldap_config.hostname = ''
    @ldap_config.port = nil
    @ldap_config.basedn = ''
    @ldap_config.filter = ''
    @ldap_config.login_mask = ''
    @ldap_config.username_attribute = ''
    @ldap_config.name_attribute = ''
    @ldap_config.last_name_attribute = ''
    @ldap_config.email_attribute = ''
    @ldap_config.roles_attribute = ''

    assert @ldap_config.invalid?
    assert_error @ldap_config, :hostname, :blank
    assert_error @ldap_config, :port, :blank
    assert_error @ldap_config, :basedn, :blank
    assert_error @ldap_config, :filter, :blank
    assert_error @ldap_config, :login_mask, :blank
    assert_error @ldap_config, :username_attribute, :blank
    assert_error @ldap_config, :name_attribute, :blank
    assert_error @ldap_config, :last_name_attribute, :blank
    assert_error @ldap_config, :email_attribute, :blank
    assert_error @ldap_config, :roles_attribute, :blank
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

  test 'validates inclusions' do
    @ldap_config.tls = 'TLSv1_x'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :tls, :inclusion
  end

  test 'validates alternative fields' do
    @ldap_config.alternative_port     = ldap_port
    @ldap_config.alternative_hostname = ''

    assert @ldap_config.invalid?
    assert_error @ldap_config, :alternative_hostname, :blank

    @ldap_config.alternative_hostname = 'localhost'
    @ldap_config.alternative_port     = 'xx'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :alternative_port, :not_a_number
  end

  test 'validates port range' do
    @ldap_config.port = 0

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :greater_than, count: 0

    @ldap_config.port = 65536

    assert @ldap_config.invalid?
    assert_error @ldap_config, :port, :less_than, count: 65536

    @ldap_config.alternative_hostname = 'localhost'

    @ldap_config.alternative_port = 0

    assert @ldap_config.invalid?
    assert_error @ldap_config, :alternative_port, :greater_than, count: 0

    @ldap_config.alternative_port = 65536

    assert @ldap_config.invalid?
    assert_error @ldap_config, :alternative_port, :less_than, count: 65536
  end

  test 'validates that can connect' do
    @ldap_config.test_user = 'admin'
    @ldap_config.test_password = 'wrong'

    assert @ldap_config.invalid?
    assert_equal @ldap_config.errors[:base], [I18n.t('message.ldap_error')]

    @ldap_config.test_password = 'admin123'
    assert @ldap_config.valid?
  end

  test 'validates CA path' do
    @ldap_config.test_user = 'admin'
    @ldap_config.test_password = 'admin123'
    @ldap_config.ca_path = '/no/file'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :ca_path, :invalid

    @ldap_config.ca_path = "#{Rails.root}/config.ru"

    assert @ldap_config.valid?
  end

  test 'ldap bind' do
    ldap = @ldap_config.ldap 'admin', 'admin123'

    assert ldap.bind
  end

  test 'ldap bind using full name' do
    username = @ldap_config.login_mask % {
      user: 'admin',
      basedn: @ldap_config.basedn
    }

    ldap = @ldap_config.ldap username, 'admin123'

    assert ldap.bind
  end

  test 'ldap bind using full name with alternative ldap' do
    assign_alternative_ldap

    username = @ldap_config.login_mask % {
      user:   'admin',
      basedn: @ldap_config.basedn
    }

    ldap = @ldap_config.ldap username, 'admin123'

    assert_raise(Net::LDAP::Error) { ldap.bind }

    ldap = @ldap_config.alternative_ldap.ldap username, 'admin123'

    assert ldap.bind
  end

  test 'ldap no bind if wrong password' do
    ldap = @ldap_config.ldap 'admin', 'wrong'

    assert !ldap.bind
  end

  test 'import' do
    set_organization organizations(:google)

    user      = users :administrator
    role      = roles :admin_second_role
    corp_role = roles :admin_second_alphabet_role

    user.update! manager_id: users(:corporate).id

    assert user.organization_roles.map(&:role_id).exclude?(role.id)
    assert user.organization_roles.map(&:role_id).exclude?(corp_role.id)

    assert_difference 'User.count' do
      @ldap_config.import 'admin', 'admin123'
    end

    assert user.reload.organization_roles.map(&:role_id).include?(role.id)
    assert user.organization_roles.map(&:role_id).include?(corp_role.id)
    assert_equal user.id, User.find_by(user: 'new_user').manager_id
    assert_nil user.manager_id
  end

  test 'import with alternative ldap' do
    set_organization organizations(:google)

    user      = users :administrator
    role      = roles :admin_second_role
    corp_role = roles :admin_second_alphabet_role

    user.update! manager_id: users(:corporate).id

    assert user.organization_roles.map(&:role_id).exclude?(role.id)
    assert user.organization_roles.map(&:role_id).exclude?(corp_role.id)

    assign_alternative_ldap

    assert_difference 'User.count' do
      @ldap_config.import 'admin', 'admin123'
    end

    assert user.reload.organization_roles.map(&:role_id).include?(role.id)
    assert user.organization_roles.map(&:role_id).include?(corp_role.id)
    assert_equal user.id, User.find_by(user: 'new_user').manager_id
    assert_nil user.manager_id
  end

  test 're-import should return all unchanged users' do
    set_organization organizations(:google)

    assert_difference 'User.count' do
      @imported_users = @ldap_config.import 'admin', 'admin123'
    end

    assert_not_includes @imported_users.map { |u| u[:state] }, :unchanged

    assert_no_difference 'User.count' do
      @not_imported_users = @ldap_config.import('admin', 'admin123')
    end

    assert_equal [:unchanged], @not_imported_users.map { |u| u[:state] }.uniq
  end

  test 'massive import' do
    user         = users(:supervisor)
    organization = organizations(:google)
    emails_count = if SHOW_WEAKNESS_EXTRA_ATTRIBUTES
                    0
                  elsif NOTIFY_NEW_ADMIN
                    2
                  else
                    1
                  end

    organization.ldap_config.update! user: 'admin', password: 'admin123'

    user.organization_roles.create! organization_id: organizations(:google).id,
                                    role_id: roles(:supervisor_google_role).id

    assert_enqueued_emails emails_count do
      assert_difference 'User.count' do
        LdapConfig.sync_users
      end
    end
  end

  test 'users limit reached' do
    set_organization organizations(:google)

    original_limit = Rails.application.credentials.auditors_limit

    Rails.application.credentials.auditors_limit = 1

    assert_no_difference 'User.count' do
      @import = @ldap_config.import 'admin', 'admin123'
    end

    assert_includes @import.map { |r| r[:state] }, :errored
    assert_includes @import.map { |r| r[:errors] },
      User.new.errors.generate_message(:base, :auditors_limit_reached)

    Rails.application.credentials.auditors_limit = original_limit
  end

  test 'test encrypt and decrypt with Security lib' do
    phrase = 'I love dogs'
    encrypted_phrase = Security.encrypt(phrase)

    assert_not_equal(phrase, encrypted_phrase)
    assert Base64.decode64(encrypted_phrase)

    decrypted_phrase = Security.decrypt(encrypted_phrase)

    assert_equal(phrase, decrypted_phrase)
  end

  test 'encrypt the same phrase' do
    phrase = 'I love dogs'

    encrypted_phrases = 5.times.map { Security.encrypt(phrase) }

    # Check all encrypted results are different
    assert_equal(5, encrypted_phrases.uniq.size)

    encrypted_phrases.each do |ep|
      decrypted_phrase = Security.decrypt(ep)

      assert_equal(phrase, decrypted_phrase, ep)
    end
  end

  test 'service password needed with service user' do
    @ldap_config.test_user = 'admin'
    @ldap_config.test_password = 'admin123'

    assert @ldap_config.valid?

    @ldap_config.user = 'admin'
    @ldap_config.password = ''
    assert @ldap_config.invalid?
    assert_error @ldap_config, :password, :blank

    @ldap_config.password = 'admin123'
    assert @ldap_config.valid?
  end

  test 'service user can connect' do
    @ldap_config.user = 'admin'
    @ldap_config.password = 'adminadmin'

    assert @ldap_config.invalid?
    assert_error @ldap_config, :user, :invalid_credentials

    @ldap_config.password = 'admin123'
    assert @ldap_config.valid?
  end

  test 'service password saved encrypted' do
    @ldap_config.update!(
      user: 'admin',
      password: 'admin123'
    )

    @ldap_config.reload
    assert @ldap_config.encrypted_password.present?
    assert_not_equal(
      @ldap_config.password,
      @ldap_config.encrypted_password
    )
    assert_equal(
      @ldap_config.password,
      @ldap_config.decrypted_password
    )
  end

  test 'get alternative ldap only once' do
    refute @ldap_config.try_alternative_ldap?

    assign_alternative_ldap

    assert @ldap_config.try_alternative_ldap?

    old_config   = @ldap_config
    @ldap_config = @ldap_config.alternative_ldap

    refute @ldap_config.try_alternative_ldap?
    refute old_config.try_alternative_ldap?

    assert_nil @ldap_config.alternative_ldap
  end

  private

    def assign_alternative_ldap
      @ldap_config.update_columns(
        hostname:             '0.0.0.1',
        alternative_hostname: 'localhost',
        alternative_port:     ldap_port
      )
    end
end
