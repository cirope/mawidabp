namespace :ldap do
  desc 'Load LDAP users and groups'
  task :reset do
    ldap_root = File.expand_path '../../test/fixtures/ldap', File.dirname(__FILE__)
    ldap_connect_string = "-x -c -h localhost -p 389 -D 'cn=admin,dc=test,dc=com' -w secret"

    puts `ldapmodify #{ldap_connect_string} -f #{File.join(ldap_root, 'clear.ldif')}`
    puts `ldapadd #{ldap_connect_string} -f #{File.join(ldap_root, 'base.ldif')}`
  end
end
