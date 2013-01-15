class AddAccessTokenToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :access_token, :string
  end
end
