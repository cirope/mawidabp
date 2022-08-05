class ChangeUserFieldLimitToUsers < ActiveRecord::Migration[6.1]
  def change
   change_column :users, :user, :string, limit: 255
   change_column :users, :email, :string, limit: 255
  end
end
