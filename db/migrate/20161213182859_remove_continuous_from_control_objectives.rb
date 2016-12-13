class RemoveContinuousFromControlObjectives < ActiveRecord::Migration
  def change
    remove_column :control_objectives, :continuous
  end
end
