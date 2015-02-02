module Organizations::LdapConfigs
  extend ActiveSupport::Concern

  included do
    has_one :ldap_config, dependent: :destroy

    accepts_nested_attributes_for :ldap_config
  end
end
