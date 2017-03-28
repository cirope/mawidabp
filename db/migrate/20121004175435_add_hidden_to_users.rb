class AddHiddenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hidden, :boolean, :default => false

    add_index :users, :hidden
  end

end
