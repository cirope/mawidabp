class AddTypeToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :type, :text
  end
end
