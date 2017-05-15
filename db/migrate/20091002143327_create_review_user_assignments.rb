class CreateReviewUserAssignments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :review_user_assignments do |t|
      t.integer :assignment_type
      t.references :review
      t.references :user

      t.timestamps null: false
    end

    add_index :review_user_assignments, [:review_id, :user_id]
  end

  def self.down
    remove_index :review_user_assignments, :column => [:review_id, :user_id]

    drop_table :review_user_assignments
  end
end
