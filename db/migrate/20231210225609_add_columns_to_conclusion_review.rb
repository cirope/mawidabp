class AddColumnsToConclusionReview < ActiveRecord::Migration[6.1]
  def change
    add_column :conclusion_reviews, :objective, :text
    add_column :conclusion_reviews, :review_conclusion, :text
    add_column :conclusion_reviews, :applied_data_analytics, :text
  end
end
