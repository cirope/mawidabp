class AddPublicToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :public, :boolean, :default => false
  end
end
