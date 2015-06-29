class CreateFindingUserAssignments < ActiveRecord::Migration
  def self.up
    create_table :finding_user_assignments do |t|
      t.boolean :process_owner, :default => false
      t.references :finding, :polymorphic => true
      t.references :user

      t.timestamps null: false
    end

    add_index :finding_user_assignments, [:finding_id, :finding_type, :user_id],
      :name => 'fua_on_id_type_and_user_id'
    add_index :finding_user_assignments, [:finding_id, :finding_type]
  end

  def self.down
    remove_index :finding_user_assignments,
      :column => [:finding_id, :finding_type, :user_id]
    remove_index :finding_user_assignments,
      :column => [:finding_id, :finding_type]

    drop_table :finding_user_assignments
  end
end
