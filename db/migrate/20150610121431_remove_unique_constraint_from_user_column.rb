class RemoveUniqueConstraintFromUserColumn < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :user
    add_index :users, :user
  end
end
