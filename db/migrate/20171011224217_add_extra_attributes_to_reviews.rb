class AddExtraAttributesToReviews < ActiveRecord::Migration[5.1]
  def change
    change_table :reviews do |t|
      t.string :scope
      t.string :risk_exposure
      t.decimal :manual_score, precision: 6, scale: 2
      t.string :include_sox
    end
  end
end
