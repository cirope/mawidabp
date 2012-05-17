class AddResponsibleAuditorToFindingUserAssignments < ActiveRecord::Migration
  def change
    add_column :finding_user_assignments, :responsible_auditor, :boolean
  end
end
