class AddKindToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :kind, :text, :default => 'private'
  end
end
