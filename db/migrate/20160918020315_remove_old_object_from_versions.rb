class RemoveOldObjectFromVersions < ActiveRecord::Migration[4.2]
  def change
    remove_column :versions, :old_object
  end
end
