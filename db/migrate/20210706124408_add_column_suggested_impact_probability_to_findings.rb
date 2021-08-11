class AddColumnSuggestedImpactProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.integer :use_suggested_impact
      t.integer :use_suggested_probability
    end
  end
end
