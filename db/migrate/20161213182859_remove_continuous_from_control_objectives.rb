class RemoveContinuousFromControlObjectives < ActiveRecord::Migration[4.2]
  def change
    remove_column :control_objectives, :continuous
  end
end
