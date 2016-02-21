class AddContinuousDefaultToFalseOnControlObjectives < ActiveRecord::Migration
  def change
    change_column_default :control_objectives, :continuous, false
    change_column_null    :control_objectives, :continuous, false
  end
end
