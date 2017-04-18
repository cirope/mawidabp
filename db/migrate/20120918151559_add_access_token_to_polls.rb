class AddAccessTokenToPolls < ActiveRecord::Migration[4.2]
  def change
    add_column :polls, :access_token, :string
  end
end
