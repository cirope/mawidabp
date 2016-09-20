class RemoveOldObjectFromVersions < ActiveRecord::Migration
  def change
    remove_column :versions, :old_object
  end
end
