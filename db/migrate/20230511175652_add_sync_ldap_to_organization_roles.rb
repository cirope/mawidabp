class AddSyncLdapToOrganizationRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_roles, :sync_ldap, :boolean, null: false, default: true
  end
end
