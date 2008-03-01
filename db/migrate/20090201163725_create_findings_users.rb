class CreateFindingsUsers < ActiveRecord::Migration
  def self.up
    create_table :findings_users, :id => false do |t|
      t.integer :finding_id
      t.integer :user_id
    end

    add_index :findings_users, [:finding_id, :user_id]
  end

  def self.down
    remove_index :findings_users, :column => [:finding_id, :user_id]

    drop_table :findings_users
  end
end