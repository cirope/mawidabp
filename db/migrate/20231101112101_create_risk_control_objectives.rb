class CreateRiskControlObjectives < ActiveRecord::Migration[6.1]
  def change
    create_table :risk_control_objectives do |t|
      t.references :risk, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :control_objective, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps
    end
  end
end
