class AddExtraAttributesToRiskAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_assessment_weights, :identifier, :string
    add_column :risk_assessment_weights, :heatmap, :boolean, null: false, default: false
    add_column :risk_assessment_weights, :owner_type, :string

    rename_column :risk_assessment_weights, :risk_assessment_template_id, :owner_id

    add_index  :risk_assessment_weights, :heatmap
    add_index  :risk_assessment_weights, [:owner_type, :owner_id]

    change_column_null :risk_assessment_weights, :weight, true
    remove_foreign_key :risk_assessment_weights, :risk_assessment_templates

    add_column :risk_assessment_templates, :formula, :string
    add_column :risk_assessments, :formula, :string

    change_column :risk_weights, :value, :decimal
    change_column_null :risk_weights, :weight, true
  end
end
