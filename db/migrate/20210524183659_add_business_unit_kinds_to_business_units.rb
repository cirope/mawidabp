class AddBusinessUnitKindsToBusinessUnits < ActiveRecord::Migration[6.0]
  def change
    change_table :business_units do |t|
      t.references :business_unit_kind, null: true, index: true
    end
  end
end
