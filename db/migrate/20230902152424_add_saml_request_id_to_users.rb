class AddSamlRequestIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :saml_request_id, :string
    add_index :users, :saml_request_id
  end
end
