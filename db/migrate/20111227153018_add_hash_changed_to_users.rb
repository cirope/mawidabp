class AddHashChangedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hash_changed, :datetime
  end
end