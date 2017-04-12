class CreateWorkflowItems < ActiveRecord::Migration[4.2]
  def self.up
    create_table :workflow_items do |t|
      t.text :task
      t.date :start
      t.date :end
      t.string :predecessors
      t.integer :order_number
      t.references :workflow

      t.timestamps null: false
    end

    add_index :workflow_items, :workflow_id
  end

  def self.down
    remove_index :workflow_items, :column => :workflow_id

    drop_table :workflow_items
  end
end
