class AddExtraAttributesToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    change_table :conclusion_reviews do |t|
      t.text :recipients
      t.text :sectors
    end
  end
end
