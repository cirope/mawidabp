class CreateRiskScoreItems < ActiveRecord::Migration[6.1]
  def change
    create_table :risk_score_items do |t|
      t.string :name, null: false
      t.decimal :value, null: false
      t.references :risk_assessment_weight, null: false, index: true, foreign_key: true

      t.timestamps
    end
  end
end
