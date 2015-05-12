class CreateBusinessUnitFindings < ActiveRecord::Migration
  def change
    create_table :business_unit_findings do |t|
      t.references :business_unit, index: true
      t.references :finding, index: true

      t.timestamps
    end

    add_foreign_key :business_unit_findings, :business_units, options: FOREIGN_KEY_OPTIONS
    add_foreign_key :business_unit_findings, :findings, options: FOREIGN_KEY_OPTIONS
  end
end
