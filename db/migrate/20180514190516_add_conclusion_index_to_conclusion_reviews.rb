class AddConclusionIndexToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :conclusion_reviews, :conclusion_index, :integer, default: nil

    add_index :conclusion_reviews, :conclusion_index
  end
end
