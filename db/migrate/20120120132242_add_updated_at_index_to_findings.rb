class AddUpdatedAtIndexToFindings < ActiveRecord::Migration
  def change
    add_index :findings, :updated_at
  end
end
