class CreateFindingUserAssignments < ActiveRecord::Migration
  def self.up
    create_table :finding_user_assignments do |t|
      t.references :finding
      t.references :user

      t.timestamps
    end

    add_index :finding_user_assignments, [:finding_id, :user_id]
  end

  def self.down
    remove_index :finding_user_assignments, :column => [:finding_id, :user_id]

    drop_table :finding_user_assignments
  end
end