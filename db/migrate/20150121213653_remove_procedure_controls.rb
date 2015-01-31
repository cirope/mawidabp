class RemoveProcedureControls < ActiveRecord::Migration
  def change
    drop_table :procedure_control_subitems
    drop_table :procedure_control_items
    drop_table :procedure_controls
  end
end
