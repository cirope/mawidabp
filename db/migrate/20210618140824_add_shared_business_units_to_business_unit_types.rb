class AddSharedBusinessUnitsToBusinessUnitTypes < ActiveRecord::Migration[6.0]
  def change
    change_table :business_unit_types do |t|
      t.boolean :shared_business_units, null: false, default: false, index: true
    end
  end
end
