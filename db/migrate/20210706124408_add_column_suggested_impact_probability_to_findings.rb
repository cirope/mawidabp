class AddColumnSuggestedImpactProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.string :use_suggested_impact
      t.string :use_suggested_probability
    end
  end
end
