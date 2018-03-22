class AddExtraClasificationAttributesToFindings < ActiveRecord::Migration[5.1]
  def change
    change_table :findings do |t|
      t.string :compliance
      t.string :operational_risk
      t.text :impact, null: false, array: true, default: []
      t.text :internal_control_components, null: false, array: true, default: []
    end
  end
end
