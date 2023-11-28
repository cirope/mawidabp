class RemoveAffectedSectorFromControlObjectives < ActiveRecord::Migration[6.1]
  def change
    remove_column :control_objectives, :affected_sector_id
  end
end
