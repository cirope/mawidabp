class AddMfaSecretToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :google_secret, :string
    add_column :users, :mfa_salt, :string
    add_column :users, :mfa_configured_at, :datetime
  end
end
