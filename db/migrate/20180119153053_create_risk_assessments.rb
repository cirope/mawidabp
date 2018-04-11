class CreateRiskAssessments < ActiveRecord::Migration[5.1]
  def change
    create_table :risk_assessments do |t|
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.references :period, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :plan, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :risk_assessment_template, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
