class AddColumnsForRiskCalculationToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :state_regulations, :integer
    add_column :findings, :degree_compliance, :integer
    add_column :findings, :observation_originated_tests, :integer
    add_column :findings, :sample_deviation, :integer
  end
end
