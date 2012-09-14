class AddOrganizationToQuestionnaires < ActiveRecord::Migration
  def change
    add_column :questionnaires, :organization_id, :integer

    add_index :questionnaires, :organization_id
  end
end
