class AddContinuousDefaultToFalseOnControlObjectives < ActiveRecord::Migration
  def change
    change_column_null :control_objectives, :continuous, false, false
  end
end
