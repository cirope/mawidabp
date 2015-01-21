class AddRelevanceToProcedureControlSubitems < ActiveRecord::Migration
  def change
    add_column :procedure_control_subitems, :relevance, :integer
  end
end
