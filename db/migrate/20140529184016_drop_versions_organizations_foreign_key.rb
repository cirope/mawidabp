class DropVersionsOrganizationsForeignKey < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :versions, :organizations
  end
end
