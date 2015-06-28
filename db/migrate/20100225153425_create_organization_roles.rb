class CreateOrganizationRoles < ActiveRecord::Migration
  def self.up
    create_table :organization_roles do |t|
      t.references :user
      t.references :organization
      t.references :role

      t.timestamps null: false
    end

    add_index :organization_roles, :user_id
    add_index :organization_roles, :organization_id
    add_index :organization_roles, :role_id
  end

  def self.down
    remove_index :organization_roles, :column => :user_id
    remove_index :organization_roles, :column => :organization_id
    remove_index :organization_roles, :column => :role_id

    drop_table :organization_roles
  end
end
