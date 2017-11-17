class AddReviewPrefixToBusinessUnitTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :business_unit_types, :review_prefix, :string
  end
end
