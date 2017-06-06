class RemovePredecessorsFromPlanItemsAndWorkflowItems < ActiveRecord::Migration[5.0]
  def change
    remove_column :plan_items, :predecessors
    remove_column :workflow_items, :predecessors
  end
end
