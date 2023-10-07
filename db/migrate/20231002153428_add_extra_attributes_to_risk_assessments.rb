class AddExtraAttributesToRiskAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_assessment_weights, :identifier, :string
    add_column :risk_assessment_weights, :heatmap, :boolean, null: false, default: false
    change_column_null :risk_assessment_weights, :weight, true
    add_index :risk_assessment_weights, :heatmap

    add_column :risk_assessment_templates, :formula, :string
  end
end
