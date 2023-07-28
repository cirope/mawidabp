class AddIdentifierToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :identifier, :string
    add_index :roles, :identifier
  end
end
