class AddParentIdsToFindings < ActiveRecord::Migration[6.0]
  def change
    if POSTGRESQL_ADAPTER
      add_column :findings, :parent_ids, :integer, array: true, default: []
      add_index :findings, :parent_ids, using: :gin
    end
  end
end
