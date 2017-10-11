class AddProgressToFindings < ActiveRecord::Migration[5.1]
  def change
    add_column :findings, :progress, :integer
  end
end
