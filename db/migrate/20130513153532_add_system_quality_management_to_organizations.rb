  class AddSystemQualityManagementToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :system_quality_management, :boolean
  end
end
