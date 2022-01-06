class AddFileModelToWorkflowItem < ActiveRecord::Migration[6.0]
  def change
    add_reference :workflow_items, :file_model, index: true,
      foreign_key: FOREIGN_KEY_OPTIONS.dup
  end
end
