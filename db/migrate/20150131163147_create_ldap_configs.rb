class CreateLdapConfigs < ActiveRecord::Migration
  def change
    create_table :ldap_configs do |t|
      t.string :hostname, null: false
      t.integer :port, null: false
      t.string :basedn, null: false
      t.string :username_ldap_attribute, null: false
      t.references :organization, index: true, null: false

      t.timestamps
    end

    add_foreign_key :ldap_configs, :organizations, options: FOREIGN_KEY_OPTIONS
  end
end
