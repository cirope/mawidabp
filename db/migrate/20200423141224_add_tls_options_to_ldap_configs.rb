class AddTlsOptionsToLdapConfigs < ActiveRecord::Migration[6.0]
  def change
    change_table :ldap_configs do |t|
      t.string :tls
      t.string :ca_path
    end
  end
end
