module LdapConfigs::LDAP
  extend ActiveSupport::Concern

  def ldap username, password
    Net::LDAP.new host: hostname, port: port, auth: {
      method:   :simple,
      username: login_mask % { user: username, basedn: basedn },
      password: password
    }
  end
end
