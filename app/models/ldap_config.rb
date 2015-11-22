class LdapConfig < ActiveRecord::Base
  include Auditable
  include Trimmer
  include LdapConfigs::LDAP
  include LdapConfigs::LDAPImport
  include LdapConfigs::Validation

  trimmed_fields :hostname, :basedn, :filter, :login_mask, :username_attribute,
    :name_attribute, :last_name_attribute, :email_attribute, :roles_attribute

  belongs_to :organization
end
