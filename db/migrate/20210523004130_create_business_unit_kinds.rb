class CreateBusinessUnitKinds < ActiveRecord::Migration[6.0]
  def change
    create_table :business_unit_kinds do |t|
      t.string :name

      t.timestamps
    end
  end
end
