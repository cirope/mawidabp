class AddRescheduleCountToFindings < ActiveRecord::Migration[5.2]
  def change
    change_table :findings do |t|
      t.integer :reschedule_count, default: 0, null: false
    end

    add_index :findings, :reschedule_count

    remove_index :findings, :rescheduled
    remove_column :findings, :rescheduled
  end
end
