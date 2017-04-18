class AddUpdatedAtIndexToFindings < ActiveRecord::Migration[4.2]
  def change
    add_index :findings, :updated_at
  end
end
