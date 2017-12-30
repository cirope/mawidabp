class AddEvolutionAttributesToConclusionReviews < ActiveRecord::Migration[5.1]
  def change
    change_table :conclusion_reviews do |t|
      t.string :evolution
      t.text :evolution_justification
    end
  end
end
