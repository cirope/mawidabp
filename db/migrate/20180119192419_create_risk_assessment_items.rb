class CreateRiskAssessmentItems < ActiveRecord::Migration[5.1]
  def change
    create_table :risk_assessment_items do |t|
      t.string :name, null: false
      t.integer :risk, null: false
      t.integer :order, null: false, default: 1
      t.references :business_unit, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :process_control, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :risk_assessment, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
