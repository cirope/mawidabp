class RemoveResourceIdFromUsers < ActiveRecord::Migration
  def change
    remove_index :users, :resource_id
    remove_column :users, :resource_id
  end
end
