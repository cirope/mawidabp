class AddFollowUpDateIndexToFindings < ActiveRecord::Migration[4.2]
  def change
    add_index :findings, :follow_up_date
  end
end
