class AddAuxiliarBusinessUnit < ActiveRecord::Migration[6.0]
  def change
    create_table :auxiliar_business_units do |t|
      t.references :plan_item, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :business_unit, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps null: false
    end
  end
end
