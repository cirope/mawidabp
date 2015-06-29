class CreateLdapConfigs < ActiveRecord::Migration
  def change
    create_table :ldap_configs do |t|
      t.string :hostname, null: false
      t.integer :port, null: false, default: 389
      t.string :basedn, null: false
      t.string :login_mask, null: false
      t.string :username_attribute, null: false
      t.string :name_attribute, null: false
      t.string :last_name_attribute, null: false
      t.string :email_attribute, null: false
      t.string :function_attribute
      t.string :roles_attribute, null: false
      t.string :manager_attribute
      t.references :organization, index: true, null: false

      t.timestamps null: false
    end

    add_foreign_key :ldap_configs, :organizations, FOREIGN_KEY_OPTIONS.dup
  end
end
