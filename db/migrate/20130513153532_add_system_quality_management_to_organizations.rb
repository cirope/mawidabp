class AddSystemQualityManagementToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :system_quality_management, :boolean
  end
end
