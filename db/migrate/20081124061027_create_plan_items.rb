class CreatePlanItems < ActiveRecord::Migration
  def self.up
    create_table :plan_items do |t|
      t.string :project
      t.date :start
      t.date :end
      t.string :predecessors
      t.integer :order_number
      t.references :plan
      t.references :business_unit

      t.timestamps null: false
    end

    add_index :plan_items, :plan_id
    add_index :plan_items, :business_unit_id
  end

  def self.down
    remove_index :plan_items, :column => :plan_id
    remove_index :plan_items, :column => :business_unit_id

    drop_table :plan_items
  end
end
