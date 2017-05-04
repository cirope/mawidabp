class AddHashChangedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hash_changed, :datetime
  end
end
