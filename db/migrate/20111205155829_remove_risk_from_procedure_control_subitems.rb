class RemoveRiskFromProcedureControlSubitems < ActiveRecord::Migration
  def up
    remove_column :procedure_control_subitems, :risk
  end

  def down
    add_column :procedure_control_subitems, :risk, :integer
  end
end
