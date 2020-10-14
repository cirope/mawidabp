class AddScoreTypeToControlObjective < ActiveRecord::Migration[6.0]
  def change
    change_table :control_objectives do |t|
      t.string :score_type, null: false, default: ControlObjective.default_score_type
    end
  end
end
