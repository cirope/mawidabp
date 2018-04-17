class AddObservationsToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :conclusion_reviews, :observations, :text
  end
end
