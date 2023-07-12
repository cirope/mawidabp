class ChangeSyncLdapColumnToOrganizationRole < ActiveRecord::Migration[6.1]
  def change
    change_column :organization_roles, :sync_ldap, :boolean, default: nil
  end
end
