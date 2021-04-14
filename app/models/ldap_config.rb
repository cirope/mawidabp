class LdapConfig < ApplicationRecord
  include Auditable
  include Trimmer
  include LdapConfigs::Defaults
  include LdapConfigs::ExtraUsersInfo
  include LdapConfigs::Ldap
  include LdapConfigs::LdapImport
  include LdapConfigs::LdapService
  include LdapConfigs::Validation

  trimmed_fields :hostname, :basedn, :filter, :login_mask, :username_attribute,
    :name_attribute, :last_name_attribute, :email_attribute, :roles_attribute

  belongs_to :organization
end
