class CreateBusinessUnitFindings < ActiveRecord::Migration
  def change
    create_table :business_unit_findings do |t|
      t.references :business_unit, index: true
      t.references :finding, index: true

      t.timestamps null: false
    end

    add_foreign_key :business_unit_findings, :business_units, FOREIGN_KEY_OPTIONS.dup
    add_foreign_key :business_unit_findings, :findings, FOREIGN_KEY_OPTIONS.dup
  end
end
