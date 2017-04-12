class AddOrganizationToQuestionnaires < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :organization_id, :integer

    add_index :questionnaires, :organization_id
  end
end
