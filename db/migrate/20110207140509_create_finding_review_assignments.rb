class CreateFindingReviewAssignments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :finding_review_assignments do |t|
      t.references :finding
      t.references :review

      t.timestamps null: false
    end

    add_index :finding_review_assignments, [:finding_id, :review_id]
  end

  def self.down
    remove_index :finding_review_assignments, :column => [:finding_id, :review_id]

    drop_table :finding_review_assignments
  end
end
