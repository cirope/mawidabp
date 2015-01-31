module LdapConfigs::Validation
  extend ActiveSupport::Concern

  included do
    validates :hostname, :port, :basedn, :username_ldap_attribute, :organization, presence: true
    validates :hostname, :basedn, :username_ldap_attribute, length: { maximum: 255 }
    validates :port, numericality: { only_integer: true, greater_than: 0, less_than: 65536 }
    validates :basedn, format: /\A(\w+=\w+)(,\w+=\w+)*\z/
    validates :username_ldap_attribute, format: /\A\w+\z/
  end
end
