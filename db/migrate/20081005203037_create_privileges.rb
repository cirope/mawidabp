class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.string :module, :limit => 100
      t.boolean :read, :default => false
      t.boolean :modify, :default => false
      t.boolean :erase, :default => false
      t.boolean :approval, :default => false
      t.references :role

      t.timestamps
    end

    add_index :privileges, :role_id
  end

  def self.down
    remove_index :privileges, :column => :role_id

    drop_table :privileges
  end
end
