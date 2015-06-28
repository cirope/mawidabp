class CreateDetracts < ActiveRecord::Migration
  def self.up
    create_table :detracts do |t|
      t.decimal :value, :precision => 3, :scale => 2
      t.text :observations
      t.references :user
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :detracts, :user_id
    add_index :detracts, :organization_id
    add_index :detracts, :created_at
  end

  def self.down
    remove_index :detracts, :column => :user_id
    remove_index :detracts, :column => :organization_id
    remove_index :detracts, :column => :created_at

    drop_table :detracts
  end
end
