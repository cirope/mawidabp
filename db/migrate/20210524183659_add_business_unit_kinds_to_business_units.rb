class AddBusinessUnitKindsToBusinessUnits < ActiveRecord::Migration[6.0]
  def change
    change_table :business_units do |t|
      t.integer :business_unit_kind_id, null: true
    end
  end
end
