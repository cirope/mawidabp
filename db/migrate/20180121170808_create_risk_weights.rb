class CreateRiskWeights < ActiveRecord::Migration[5.1]
  def change
    create_table :risk_weights do |t|
      t.integer :value, null: false
      t.integer :weight, null: false
      t.references :risk_assessment_weight, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :risk_assessment_item, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
