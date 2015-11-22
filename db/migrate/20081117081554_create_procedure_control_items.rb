class CreateProcedureControlItems < ActiveRecord::Migration
  def self.up
    create_table :procedure_control_items do |t|
      t.integer :aproach
      t.integer :frequency
      t.integer :order
      t.references :process_control
      t.references :procedure_control
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :procedure_control_items, :process_control_id
    add_index :procedure_control_items, :procedure_control_id
  end

  def self.down
    remove_index :procedure_control_items, :column => :process_control_id
    remove_index :procedure_control_items, :column => :procedure_control_id

    drop_table :procedure_control_items
  end
end
