class AddIssuesAndAlertCountsToControlObjectiveItems < ActiveRecord::Migration[5.1]
  def change
    change_table :control_objective_items do |t|
      t.integer :issues_count
      t.integer :alerts_count
    end
  end
end
