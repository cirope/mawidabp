class AddIndependentIdentificationToBusinessUnitTypes < ActiveRecord::Migration[6.0]
  def change
    change_table :business_unit_types do |t|
      t.boolean :independent_identification, null: false, default: false
    end
  end
end
