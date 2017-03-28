class CreateControlObjectives < ActiveRecord::Migration[4.2]
  def self.up
    create_table :control_objectives do |t|
      t.text :name
      t.integer :risk
      t.integer :relevance
      t.integer :order
      t.references :process_control

      t.timestamps null: false
    end

    add_index :control_objectives, :process_control_id
  end

  def self.down
    remove_index :control_objectives, :column => :process_control_id

    drop_table :control_objectives
  end
end
