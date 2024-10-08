class AddRequireMfaToOrganizationRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_roles, :require_mfa, :boolean, null: false, default: false
  end
end
