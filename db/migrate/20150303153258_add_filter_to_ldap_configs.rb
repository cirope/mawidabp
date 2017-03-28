class AddFilterToLdapConfigs < ActiveRecord::Migration[4.2]
  def change
    add_column :ldap_configs, :filter, :string
  end
end
