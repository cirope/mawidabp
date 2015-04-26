class AddContinuousToControlObjectives < ActiveRecord::Migration
  def change
    add_column :control_objectives, :continuous, :boolean
  end
end
