class AddExtraAttributesToRiskAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_assessment_weights, :identifier, :string
    add_column :risk_assessment_weights, :heatmap, :boolean, null: false, default: false
    add_column :risk_assessment_templates, :formula, :string
    add_column :risk_assessments, :formula, :string
    add_column :risk_weights, :identifier, :string

    change_column_null :risk_weights, :weight, true
    change_column_null :risk_assessment_weights, :weight, true

    add_index :risk_assessment_weights, :heatmap
  end
end
