class CreateOldPasswords < ActiveRecord::Migration
  def self.up
    create_table :old_passwords do |t|
      t.string :password
      t.references :user

      t.timestamps
    end

    add_index :old_passwords, :user_id
    add_index :old_passwords, :created_at
  end

  def self.down
    remove_index :old_passwords, :column => :user_id
    remove_index :old_passwords, :column => :created_at

    drop_table :old_passwords
  end
end