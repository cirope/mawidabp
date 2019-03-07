class AddLastNotificationDateToFindings < ActiveRecord::Migration[5.2]
  def change
    change_table :findings do |t|
      t.date :last_notification_date
    end

    add_index :findings, :last_notification_date
  end
end
