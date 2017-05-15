class AddRelevanceToProcedureControlSubitems < ActiveRecord::Migration[4.2]
  def change
    add_column :procedure_control_subitems, :relevance, :integer
  end
end
