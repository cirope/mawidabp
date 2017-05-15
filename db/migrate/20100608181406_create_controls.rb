class CreateControls < ActiveRecord::Migration[4.2]
  def self.up
    create_table :controls do |t|
      t.text :control
      t.text :effects
      t.text :design_tests
      t.text :compliance_tests
      t.text :sustantive_tests
      t.integer :order
      t.references :controllable, :polymorphic => true

      t.timestamps null: false
    end

    add_index :controls, [:controllable_type, :controllable_id]
  end

  def self.down
    remove_index :controls, :column => [:controllable_type, :controllable_id]

    drop_table :controls
  end
end
