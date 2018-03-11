class AddObjectChangesIndexToVersionsOnPostgreSql < ActiveRecord::Migration[5.1]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      add_index :versions, :object_changes, using: :gin
    end
  end
end
