class AddAltScoresToReviews < ActiveRecord::Migration[6.0]
  def change
    change_table :reviews do |t|
      t.integer :score_alt, null: false, default: 100
      t.decimal :manual_score_alt, precision: 6, scale: 2
    end
  end
end
