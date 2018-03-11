class AddShortAlternativePdfAttributesToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :conclusion_reviews, :main_weaknesses_text, :text
    add_column :conclusion_reviews, :corrective_actions, :text
    add_column :conclusion_reviews, :affects_compliance, :boolean, null: false, default: false
  end
end
