class AddCorporateToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :corporate, :boolean, null: false, default: false

    add_index :organizations, :corporate
  end
end
