class ResetFirstFollowUpDateOnFindings < ActiveRecord::Migration[6.0]
  def change
    remove_index :findings, :first_follow_up_date
    remove_column :findings, :first_follow_up_date

    add_column :findings, :first_follow_up_date, :date
    add_index :findings, :first_follow_up_date
  end
end
