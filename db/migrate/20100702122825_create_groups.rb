class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name
      t.string :admin_email
      t.string :admin_hash
      t.text :description
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :groups, :name, :unique => true
    add_index :groups, :admin_email, :unique => true
    add_index :groups, :admin_hash, :unique => true
  end

  def self.down
    remove_index :groups, :column => :name
    remove_index :groups, :column => :admin_email
    remove_index :groups, :column => :admin_hash

    drop_table :groups
  end
end