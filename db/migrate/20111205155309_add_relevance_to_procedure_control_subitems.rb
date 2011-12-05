class AddRelevanceToProcedureControlSubitems < ActiveRecord::Migration
  def change
    add_column :procedure_control_subitems, :relevance, :integer
    
    ProcedureControlSubitem.reset_column_information
    
    all_done = ProcedureControlSubitem.all.all? do |pcs|
      pcs.update_attribute :relevance, pcs.control_objective.relevance
    end
    
    raise 'Some procedure control subitems has errors' unless all_done
  end
end