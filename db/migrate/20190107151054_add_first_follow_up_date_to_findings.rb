class AddFirstFollowUpDateToFindings < ActiveRecord::Migration[5.2]
  def change
    add_column :findings, :first_follow_up_date, :date
    add_index :findings, :first_follow_up_date
  end
end
