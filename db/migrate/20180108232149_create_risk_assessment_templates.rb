class CreateRiskAssessmentTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :risk_assessment_templates do |t|
      t.string :name, null: false
      t.text :description
      t.integer :lock_version, null: false, default: 0
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
