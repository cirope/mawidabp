class CreatePeriods < ActiveRecord::Migration
  def self.up
    create_table :periods do |t|
      t.integer :number
      t.text :description
      t.date :start
      t.date :end
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :periods, :organization_id
    add_index :periods, :start
    add_index :periods, :end
  end

  def self.down
    remove_index :periods, :column => :organization_id

    drop_table :periods
  end
end