class RemovePublicAndSystemQualityManagementFromOrganizations < ActiveRecord::Migration
  def up
    remove_column :organizations, :public
    remove_column :organizations, :system_quality_management
  end

  def down
    add_column :organizations, :public
    add_column :organizations, :system_quality_management
  end
end
