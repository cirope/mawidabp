class AddColumnRequireDetailToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.boolean :require_detail, null: false, default: false
    end
  end
end
