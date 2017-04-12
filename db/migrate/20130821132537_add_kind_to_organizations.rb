class AddKindToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :kind, :text, :default => 'private'
  end
end
