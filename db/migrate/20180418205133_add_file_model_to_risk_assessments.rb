class AddFileModelToRiskAssessments < ActiveRecord::Migration[5.1]
  def change
    add_reference :risk_assessments, :file_model, index: true,
      foreign_key: FOREIGN_KEY_OPTIONS.dup
  end
end
