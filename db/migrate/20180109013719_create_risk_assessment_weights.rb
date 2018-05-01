class CreateRiskAssessmentWeights < ActiveRecord::Migration[5.1]
  def change
    create_table :risk_assessment_weights do |t|
      t.string :name, null: false
      t.text :description
      t.integer :weight, null: false
      t.references :risk_assessment_template, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
