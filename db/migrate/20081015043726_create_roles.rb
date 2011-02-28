class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
      t.integer :role_type
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :roles, :organization_id
    add_index :roles, :name
  end

  def self.down
    remove_index :roles, :column => :organization_id
    remove_index :roles, :column => :name

    drop_table :roles
  end
end