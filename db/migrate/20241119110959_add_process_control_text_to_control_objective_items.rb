class AddProcessControlTextToControlObjectiveItems < ActiveRecord::Migration[6.1]
  def change
    add_column :control_objective_items, :process_control_text, :text
  end
end
