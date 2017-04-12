class AddExcludeFromScoreToControlObjectiveItems < ActiveRecord::Migration[4.2]
  def change
    add_column :control_objective_items, :exclude_from_score, :boolean,
      :null => false, :default => false
  end
end
