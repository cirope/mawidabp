class ChangeUserFieldLimitToUsers < ActiveRecord::Migration[6.1]
  def change
   change_column :users, :user, :string, limit: 255
  end
end
