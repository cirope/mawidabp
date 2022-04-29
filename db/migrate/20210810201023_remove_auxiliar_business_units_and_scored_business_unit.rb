class RemoveAuxiliarBusinessUnitsAndScoredBusinessUnit < ActiveRecord::Migration[6.0]
  def change
    drop_table :auxiliar_business_units

    remove_reference :control_objective_items, :scored_business_unit, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_units)
  end
end
