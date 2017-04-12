class AddOrganizationToPolls < ActiveRecord::Migration[4.2]
  def change
    add_column :polls, :organization_id, :integer

    add_index :polls, :organization_id
  end
end
