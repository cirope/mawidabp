class CreateUsers < ActiveRecord::Migration[4.2]
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
      t.boolean :group_admin, :default => false
      t.references :resource
      t.datetime :last_access
      t.integer :manager_id
      t.integer :failed_attempts, :default => 0
      t.text :notes
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :users, :user, :unique => true
    add_index :users, :email, :unique => true
    add_index :users, :change_password_hash, :unique => true
    add_index :users, :resource_id
    add_index :users, :manager_id
    add_index :users, :group_admin
  end

  def self.down
    remove_index :users, :column => :user
    remove_index :users, :column => :email
    remove_index :users, :column => :change_password_hash
    remove_index :users, :column => :resource_id
    remove_index :users, :column => :manager_id
    remove_index :users, :column => :group_admin

    drop_table :users
  end
end
