module LdapConfigs::LDAP
  extend ActiveSupport::Concern

  def ldap username, password
    Net::LDAP.new host: hostname, port: port, auth: {
      method:   :simple,
      username: "#{username_ldap_attribute}=#{username},#{basedn}",
      password: password
    }
  end
end
