class AddPreviousDataToConclusionReview < ActiveRecord::Migration[5.2]
  def change
    change_table :conclusion_reviews do |t|
      t.string :previous_identification
      t.date :previous_date
    end
  end
end
