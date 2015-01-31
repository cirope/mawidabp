class LdapConfig < ActiveRecord::Base
  include Auditable
  include Trimmer
  include LdapConfigs::Validation

  trimmed_fields :hostname, :basedn, :username_ldap_attribute

  belongs_to :organization

  def ldap username, password
    Net::LDAP.new host: hostname, port: port, auth: {
      method:   :simple,
      username: "#{username_ldap_attribute}=#{username},#{basedn}",
      password: password
    }
  end
end
