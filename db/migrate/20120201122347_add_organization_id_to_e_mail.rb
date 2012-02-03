class AddOrganizationIdToEMail < ActiveRecord::Migration
  def change
    add_column :e_mails, :organization_id, :integer
    
    add_index :e_mails, :organization_id
  end
end
