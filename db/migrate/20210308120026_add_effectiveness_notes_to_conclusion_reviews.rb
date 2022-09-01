class AddEffectivenessNotesToConclusionReviews < ActiveRecord::Migration[6.0]
  def change
    change_table :conclusion_reviews do |t|
      t.text :effectiveness_notes
    end
  end
end
