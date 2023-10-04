class AddExtraAttributesToRiskAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_assessment_weights, :identifier, :string
    add_column :risk_assessment_templates, :formula, :string

    change_column_null :risk_assessment_weights, :weight, true
  end
end
