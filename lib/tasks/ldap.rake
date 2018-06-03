namespace :ldap do
  desc 'Load LDAP users and groups'
  task :reset do
    ldap_root = File.expand_path '../../test/fixtures/ldap', File.dirname(__FILE__)
    ldap_port = ENV['TRAVIS'] ? 3389 : 389
    ldap_connect_string = "-x -c -h localhost -p #{ldap_port} -D 'cn=admin,dc=test,dc=com' -w secret"

    puts `ldapmodify #{ldap_connect_string} -f #{File.join(ldap_root, 'clear.ldif')}`
    puts `ldapadd #{ldap_connect_string} -f #{File.join(ldap_root, 'base.ldif')}`
  end

  desc 'Massive Import LDAP users and groups'
  task global_import: :environment do
    # Organization.where(corporate: false).joins(:ldap_config).each do |o|
    LdapConfig.with_user.preload(:organization).each do |ldap|
      ::Rails.logger.info("[#{ldap.organization.prefix.upcase}] Importing users for #{ldap.basedn}")

      begin
        imports = ldap.service_import
        # LdapMailer.import_notifier(imports, o).deliver_later
      rescue ::StandardError=> e
        ::Rails.logger.error(e)
      end
    end
  end
end
