class LdapConfig < ActiveRecord::Base
  include Auditable
  include Trimmer
  include LdapConfigs::Validation

  trimmed_fields :hostname, :basedn, :username_ldap_attribute

  belongs_to :organization
end
