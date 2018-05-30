require 'test_helper'

class NotifierMailerTest < ActionMailer::TestCase
  fixtures :users, :organizations, :groups, :organization_roles, :roles,
    :ldap_configs

  setup do
    ActionMailer::Base.deliveries.clear

    assert ActionMailer::Base.deliveries.empty?
  end

  teardown do
    Organization.current_id = nil
  end

  test 'Notify with imported users' do
    Organization.current_id = organizations(:google).id

    ldap_config = ldap_configs(:google_ldap)
    imports = ldap_config.import('admin', 'admin123')

    response = LdapMailer.import_notifier(imports).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert_includes response.to, users(:supervisor).email
  end
end
