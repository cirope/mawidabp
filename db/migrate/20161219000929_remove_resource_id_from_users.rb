class RemoveResourceIdFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :resource_id
    remove_column :users, :resource_id
  end
end
