class ChangeActivityToTimeConsumptions < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :time_consumptions, :activities
    rename_column :time_consumptions, :activity_id, :resource_id
    add_column :time_consumptions, :resource_type, :string, default: 'Activity'
  end
end
