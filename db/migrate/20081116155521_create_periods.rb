class CreatePeriods < ActiveRecord::Migration
  def self.up
    create_table :periods do |t|
      t.integer :number
      t.text :description
      t.date :start
      t.date :end
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :periods, :organization_id
    add_index :periods, :start
    add_index :periods, :end
    add_index :periods, :number
  end

  def self.down
    remove_index :periods, :column => :organization_id
    remove_index :periods, :column => :start
    remove_index :periods, :column => :end
    remove_index :periods, :column => :number

    drop_table :periods
  end
end
