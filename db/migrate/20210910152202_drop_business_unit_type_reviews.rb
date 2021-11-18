class DropBusinessUnitTypeReviews < ActiveRecord::Migration[6.0]
  def change
    drop_table :business_unit_type_reviews
  end
end
