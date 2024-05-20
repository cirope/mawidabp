class AddPlanItemToRiskAssessmentItem < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_assessment_items, :plan_item_id, :integer
  end
end
