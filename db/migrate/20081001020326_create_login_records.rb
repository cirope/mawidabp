class CreateLoginRecords < ActiveRecord::Migration[4.2]
  def self.up
    create_table :login_records do |t|
      t.references :user
      t.text :data
      t.datetime :start
      t.datetime :end
      t.datetime :created_at
      t.references :organization
    end

    add_index :login_records, :user_id
    add_index :login_records, :start
    add_index :login_records, :end
    add_index :login_records, :organization_id
  end

  def self.down
    remove_index :login_records, :column => :user_id
    remove_index :login_records, :column => :start
    remove_index :login_records, :column => :end
    remove_index :login_records, :column => :organization_id

    drop_table :login_records
  end
end
