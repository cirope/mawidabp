class ChangeActivityToTimeConsumptions < ActiveRecord::Migration[6.0]
  def change
    rename_column :time_consumptions, :activity_id, :resource_on_id
    add_column :time_consumptions, :resource_on_type, :string, default: 'Activity'
    remove_foreign_key :time_consumptions, :activities
  end
end
