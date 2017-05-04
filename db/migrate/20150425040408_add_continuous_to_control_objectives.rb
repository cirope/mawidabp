class AddContinuousToControlObjectives < ActiveRecord::Migration[4.2]
  def change
    add_column :control_objectives, :continuous, :boolean
  end
end
