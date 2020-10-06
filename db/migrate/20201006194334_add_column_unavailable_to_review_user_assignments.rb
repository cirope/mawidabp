class AddColumnUnavailableToReviewUserAssignments < ActiveRecord::Migration[6.0]
  def change
    change_table :review_user_assignments do |t|
      t.boolean :unavailable, null: false, default: true
    end
  end
end
