class CreateProcedureControlSubitems < ActiveRecord::Migration
  def self.up
    create_table :procedure_control_subitems do |t|
      t.text :control_objective_text
      t.text :main_procedures
      t.text :design_tests
      t.text :compliance_tests
      t.text :effects
      t.integer :risk
      t.integer :order
      t.references :control_objective
      t.references :procedure_control_item

      t.timestamps
    end

    add_index :procedure_control_subitems, :control_objective_id
    add_index :procedure_control_subitems, :procedure_control_item_id
  end

  def self.down
    remove_index :procedure_control_subitems, :column => :control_objective_id
    remove_index :procedure_control_subitems,
      :column => :procedure_control_item_id

    drop_table :procedure_control_subitems
  end
end