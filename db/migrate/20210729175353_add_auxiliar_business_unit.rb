class AddAuxiliarBusinessUnit < ActiveRecord::Migration[6.0]
  def change
    create_table :auxiliar_business_unit_in_plan_items do |t|
      t.belongs_to :plan_item, index: true
      t.belongs_to :business_unit, index: true
      t.timestamps
    end
  end
end
