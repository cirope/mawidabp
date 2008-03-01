class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.integer :status
      t.string :confirmation_hash
      t.text :notes
      t.references :user
      t.references :user_who_confirm
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :notifications, :confirmation_hash, :unique => true
    add_index :notifications, :user_id
    add_index :notifications, :status
    add_index :notifications, :user_who_confirm_id
  end

  def self.down
    remove_index :notifications, :column => :confirmation_hash
    remove_index :notifications, :column => :user_id
    remove_index :notifications, :column => :status
    remove_index :notifications, :column => :user_who_confirm_id

    drop_table :notifications
  end
end