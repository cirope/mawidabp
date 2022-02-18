class AddFollowUpDateLastChangedToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :follow_up_date_last_changed, :date
    add_index :findings, :follow_up_date_last_changed
  end
end
