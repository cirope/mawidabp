class AddColumnReviewObjectiveAndTypeReviewToReviews < ActiveRecord::Migration[6.0]
  def change
    change_table :reviews do |t|
      t.text :review_objective
      t.integer :type_review
    end
  end
end
