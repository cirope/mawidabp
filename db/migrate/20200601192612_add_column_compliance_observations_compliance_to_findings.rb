class AddColumnComplianceObservationsComplianceToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :compliance_observations, :text
  end
end
