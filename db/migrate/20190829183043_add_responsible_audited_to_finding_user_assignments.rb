class AddResponsibleAuditedToFindingUserAssignments < ActiveRecord::Migration[6.0]
  def change
    change_table :finding_user_assignments do |t|
      t.boolean :responsible_audited, null: false, default: false
    end
  end
end
