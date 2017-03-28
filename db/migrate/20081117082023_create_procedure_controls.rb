class CreateProcedureControls < ActiveRecord::Migration[4.2]
  def self.up
    create_table :procedure_controls do |t|
      t.references :period
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :procedure_controls, :period_id
    add_index :procedure_controls, :created_at
  end

  def self.down
    remove_index :procedure_controls, :column => :period_id
    remove_index :procedure_controls, :column => :created_at

    drop_table :procedure_controls
  end
end
