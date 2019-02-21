class AddBicAttributesToConclusionReviews < ActiveRecord::Migration[5.2]
  def change
    change_table :conclusion_reviews do |t|
      t.text :objective
      t.text :reference
      t.text :scope
    end
  end
end
