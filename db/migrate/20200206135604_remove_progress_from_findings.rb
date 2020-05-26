class RemoveProgressFromFindings < ActiveRecord::Migration[6.0]
  def change
    remove_column :findings, :progress
  end
end
