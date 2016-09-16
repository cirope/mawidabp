class AddObjectAndObjectChangesToVersions < ActiveRecord::Migration
  def change
    rename_column :versions, :object, :old_object

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_column :versions, :object, :jsonb
      add_column :versions, :object_changes, :jsonb
    else
      add_column :versions, :object, :text
      add_column :versions, :object_changes, :text
    end
  end
end
