class CreateBusinessUnitTypeUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :business_unit_type_users do |t|
      t.references :business_unit_type, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
