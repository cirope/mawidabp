class AddCreatedAtIndexToConclusionReviews < ActiveRecord::Migration[6.1]
  def change
    add_index :conclusion_reviews, :created_at
  end
end
