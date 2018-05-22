class AddServiceLoginToLdapConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :ldap_configs, :service_user, :string, default: nil
    add_column :ldap_configs, :encrypted_service_password, :string, default: nil
  end
end
