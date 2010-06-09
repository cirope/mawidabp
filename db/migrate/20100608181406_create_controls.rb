class CreateControls < ActiveRecord::Migration
  def self.up
    create_table :controls do |t|
      t.text :control
      t.text :effects
      t.text :compliance_tests
      t.text :design_tests
      t.integer :order
      t.references :controllable, :polymorphic => true

      t.timestamps
    end

    add_index :controls, [:controllable_type, :controllable_id]
  end

  def self.down
    remove_index :controls, :column => [:controllable_type, :controllable_id]

    drop_table :controls
  end
end