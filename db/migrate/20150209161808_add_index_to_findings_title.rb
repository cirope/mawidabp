class AddIndexToFindingsTitle < ActiveRecord::Migration
  def change
    add_index :findings, :title
  end
end
