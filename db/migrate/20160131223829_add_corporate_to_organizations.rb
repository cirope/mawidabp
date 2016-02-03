class AddCorporateToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :corporate, :boolean, null: false, default: false

    add_index :organizations, :corporate
  end
end
