class CreateDetracts < ActiveRecord::Migration
  def self.up
    create_table :detracts do |t|
      t.decimal :value, :precision => 3, :scale => 2
      t.text :observations
      t.references :user
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :detracts, :user_id
    add_index :detracts, :organization_id
  end

  def self.down
    remove_index :detracts, :column => :user_id
    remove_index :detracts, :column => :organization_id

    drop_table :detracts
  end
end