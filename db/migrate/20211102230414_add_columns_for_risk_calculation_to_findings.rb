class AddColumnsForRiskCalculationToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :state_regulations, :integer
    add_column :findings, :degree_compliance, :integer
    add_column :findings, :observation_originated_tests, :integer
    add_column :findings, :sample_deviation, :integer
    add_column :findings, :external_repeated, :integer
    add_column :findings, :risk_justification, :text
  end
end
