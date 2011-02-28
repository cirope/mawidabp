class CreateErrorRecords < ActiveRecord::Migration
  def self.up
    create_table :error_records do |t|
      t.text :data
      t.integer :error
      t.references :user
      t.references :organization

      t.timestamps
    end

    add_index :error_records, :user_id
    add_index :error_records, :organization_id
    add_index :error_records, :created_at
  end

  def self.down
    remove_index :error_records, :column => :user_id
    remove_index :error_records, :column => :organization_id
    remove_index :error_records, :column => :created_at

    drop_table :error_records
  end
end