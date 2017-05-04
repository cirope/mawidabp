class AddIndexToFindingsTitle < ActiveRecord::Migration[4.2]
  def change
    add_index :findings, :title
  end
end
