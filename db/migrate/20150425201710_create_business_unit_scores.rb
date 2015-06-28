class CreateBusinessUnitScores < ActiveRecord::Migration
  def change
    create_table :business_unit_scores do |t|
      t.integer :design_score
      t.integer :compliance_score
      t.integer :sustantive_score
      t.references :business_unit, index: true
      t.references :control_objective_item, index: true

      t.timestamps
    end

    add_foreign_key :business_unit_scores, :business_units, FOREIGN_KEY_OPTIONS.dup
    add_foreign_key :business_unit_scores, :control_objective_items, FOREIGN_KEY_OPTIONS.dup
  end
end
