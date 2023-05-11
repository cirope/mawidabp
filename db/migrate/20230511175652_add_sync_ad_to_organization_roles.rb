class AddSyncAdToOrganizationRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_roles, :sync_ad, :boolean, null: false, default: true
  end
end
