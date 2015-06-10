class RemoveUniqueConstraintFromUserColumn < ActiveRecord::Migration
  def change
    remove_index :users, :user
    add_index :users, :user
  end
end
