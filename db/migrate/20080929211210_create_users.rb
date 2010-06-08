class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :limit => 100
      t.string :last_name, :limit => 100
      t.string :language, :limit => 10
      t.string :email, :limit => 100
      t.string :user, :limit => 30
      t.string :function
      t.string :password, :limit => 128
      t.string :salt
      t.string :change_password_hash
      t.date :password_changed
      t.boolean :enable, :default => false
      t.boolean :logged_in, :default => false
      t.references :resource
      t.datetime :last_access
      t.integer :manager_id
      t.integer :failed_attempts, :default => 0
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :users, :user, :unique => true
    add_index :users, :email, :unique => true
    add_index :users, :change_password_hash, :unique => true
    add_index :users, :resource_id
    add_index :users, :manager_id
  end

  def self.down
    remove_index :users, :column => :user
    remove_index :users, :column => :email
    remove_index :users, :column => :change_password_hash
    remove_index :users, :column => :resource_id
    remove_index :users, :column => :manager_id

    drop_table :users
  end
end