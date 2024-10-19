class AddFindingStateChangeNotificationToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :finding_state_change_notification, :boolean, null: false, default: false
  end
end
