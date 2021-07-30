class AddScoredBusinessUnitInControlObjectiveItem < ActiveRecord::Migration[6.0]
  def change
    add_column :control_objective_items, :scored_business_unit_id, :integer, null: true
    add_foreign_key :control_objective_items, :business_units, column: :scored_business_unit_id
  end
end
