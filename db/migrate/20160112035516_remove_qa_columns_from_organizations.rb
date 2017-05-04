class RemoveQaColumnsFromOrganizations < ActiveRecord::Migration[4.2]
  def change
    remove_column :organizations, :system_quality_management, :boolean
    remove_column :organizations, :public, :boolean
    remove_column :organizations, :kind, :string
  end
end
