class AddColumnSuggestedImpactProbabilityToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.boolean :suggested_impact, default: false
      t.boolean :suggested_probability, default: false
    end
  end
end
