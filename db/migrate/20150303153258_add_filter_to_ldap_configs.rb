class AddFilterToLdapConfigs < ActiveRecord::Migration
  def change
    add_column :ldap_configs, :filter, :string
  end
end
