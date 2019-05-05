class RemoveObjectiveFromConclusionReviews < ActiveRecord::Migration[5.2]
  def change
    remove_column :conclusion_reviews, :objective, :text
  end
end
