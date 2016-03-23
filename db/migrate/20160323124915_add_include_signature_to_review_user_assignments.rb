class AddIncludeSignatureToReviewUserAssignments < ActiveRecord::Migration
  def change
    add_column :review_user_assignments, :include_signature, :boolean, null: false, default: true
  end
end
