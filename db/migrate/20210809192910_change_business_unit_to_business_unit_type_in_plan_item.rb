class ChangeBusinessUnitToBusinessUnitTypeInPlanItem < ActiveRecord::Migration[6.0]
  def up
    drop_table :auxiliar_business_units

    create_table :auxiliar_business_unit_types do |t|
      t.references :plan_item, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :business_unit_type, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps null: false
    end

    remove_reference :control_objective_items, :scored_business_unit, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_units)

    change_table :control_objective_items do |t|
      t.references :scored_business_unit_type, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_unit_types)
    end
  end

  def down
    drop_table :auxiliar_business_unit_types

    create_table :auxiliar_business_units do |t|
      t.references :plan_item, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :business_unit, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps null: false
    end

    remove_reference :control_objective_items, :scored_business_unit_type, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_unit_types)

    change_table :control_objective_items do |t|
      t.references :scored_business_unit, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_units)
    end
  end
end
