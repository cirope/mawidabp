class AddScoredBusinessUnitInControlObjectiveItem < ActiveRecord::Migration[6.0]
  def change
    change_table :control_objective_items do |t|
      t.references :scored_business_unit, index: true, foreign_key: FOREIGN_KEY_OPTIONS.merge(to_table: :business_units)
    end
  end
end
