class ChangeComplianceSusceptibleToSanctionNameOnFindings < ActiveRecord::Migration[6.1]
  def change
    rename_column :findings, :compliance_susceptible_to_sanction, :compliance_maybe_sanction
  end
end
