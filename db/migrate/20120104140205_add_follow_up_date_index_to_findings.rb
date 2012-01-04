class AddFollowUpDateIndexToFindings < ActiveRecord::Migration
  def change
    add_index :findings, :follow_up_date
  end
end