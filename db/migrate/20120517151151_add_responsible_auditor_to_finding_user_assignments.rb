class AddResponsibleAuditorToFindingUserAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :finding_user_assignments, :responsible_auditor, :boolean
  end
end
