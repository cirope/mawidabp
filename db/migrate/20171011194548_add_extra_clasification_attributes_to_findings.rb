class AddExtraClasificationAttributesToFindings < ActiveRecord::Migration[5.1]
  def change
    change_table :findings do |t|
      t.string :compliance
      t.string :operational_risk
      t.text :impact, null: false, array: true, default: [].to_json
      t.text :internal_control_components, null: false, array: true, default: [].to_json
    end
  end
end
