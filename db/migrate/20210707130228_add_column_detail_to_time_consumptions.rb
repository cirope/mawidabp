class AddColumnDetailToTimeConsumptions < ActiveRecord::Migration[6.0]
  def change
    change_table :time_consumptions do |t|
      t.text :detail
    end
  end
end
