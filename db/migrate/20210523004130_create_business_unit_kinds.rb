class CreateBusinessUnitKinds < ActiveRecord::Migration[6.0]
  def change
    create_table :business_unit_kinds do |t|
      t.string :name, null: false
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
