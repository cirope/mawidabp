class AddOwnerToReviewUserAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :review_user_assignments, :owner, :boolean, null: false, default: false
  end
end
