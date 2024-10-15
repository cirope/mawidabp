class AddMfaSecretToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :google_secret, :string
    add_column :users, :mfa_secret, :string
    add_column :users, :mfa_done, :boolean, null: false, default: false
  end
end
