class AddSharedToRiskAssessments < ActiveRecord::Migration[5.2]
  def change
    change_table :risk_assessments do |t|
      t.boolean :shared, index: true, null: false, default: false
      t.references :group, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
    end

    put_group_id_on_risk_assessments

    change_column_null :risk_assessments, :group_id, false
  end

  private

    def put_group_id_on_risk_assessments
      RiskAssessment.reset_column_information

      risk_assessments.find_each do |risk_assessment|
        group_id = risk_assessment.organization.group_id

        risk_assessment.update_column :group_id, group_id
      end
    end

    def risk_assessments
      RiskAssessment.unscoped.all.includes :organization
    end
end
