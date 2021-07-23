class AddColumnSuggestedImpactProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.boolean :use_suggested_impact, default: false, null: false
      t.boolean :use_suggested_probability, default: false, null: false
    end
  end
end
