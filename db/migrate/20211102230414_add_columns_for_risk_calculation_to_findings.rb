class AddColumnsForRiskCalculationToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :state_regulations, :integer, default: 0
    add_column :findings, :degree_compliance, :integer, default: 0
    add_column :findings, :observation_originated_tests, :integer, default: 0
    add_column :findings, :sample_deviation, :integer, default: 0
  end
end
