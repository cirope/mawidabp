class AddLicensedToGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :licensed, :boolean, default: false
  end
end
