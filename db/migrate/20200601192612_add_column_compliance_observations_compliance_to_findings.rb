class AddColumnComplianceObservationsComplianceToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      t.text :compliance_observations
    end
  end
end
