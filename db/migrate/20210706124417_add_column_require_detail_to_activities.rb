class AddColumnRequireDetailToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.boolean :require_detail, default: false
    end
  end
end
