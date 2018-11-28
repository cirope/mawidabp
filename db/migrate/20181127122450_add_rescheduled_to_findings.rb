class AddRescheduledToFindings < ActiveRecord::Migration[5.2]
  def change
    change_table :findings do |t|
      t.boolean :rescheduled, default: false, null: false
    end

    add_index :findings, :rescheduled
  end
end
