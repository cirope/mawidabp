class AddExcludeFromScoreToControlObjectiveItems < ActiveRecord::Migration
  def change
    add_column :control_objective_items, :exclude_from_score, :boolean,
      :null => false, :default => false
  end
end
