class AddRiskExposureToPlanItems < ActiveRecord::Migration[5.1]
  def change
    add_column :plan_items, :risk_exposure, :string
  end
end
