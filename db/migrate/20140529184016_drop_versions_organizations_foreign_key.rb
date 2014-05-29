class DropVersionsOrganizationsForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key :versions, :organizations
  end
end
