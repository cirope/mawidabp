class AddDraftReviewCodeToFindings < ActiveRecord::Migration[6.1]
  def change
    add_column :findings, :draft_review_code, :string
  end
end
