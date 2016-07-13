class AddOwnerToReviewUserAssignments < ActiveRecord::Migration
  def change
    add_column :review_user_assignments, :owner, :boolean, null: false, default: false
  end
end
