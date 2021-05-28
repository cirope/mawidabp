class AddProbabilityAndImpactAndManualRiskToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.integer :probability
      t.integer :impact_risk
      t.boolean :manual_risk, null: false, default: true
    end
  end
end
