class AddMainRecommendationsToConclusionReviews < ActiveRecord::Migration[5.2]
  def change
    change_table :conclusion_reviews do |t|
      t.text :main_recommendations
    end
  end
end
