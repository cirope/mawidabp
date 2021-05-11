class CreateBusinessUnitTypeReviews < ActiveRecord::Migration[6.0]
  def change
    create_table :business_unit_type_reviews do |t|
      t.references :business_unit_type, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :review, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
