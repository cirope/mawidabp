class AddFieldsInBusinessUnitTypesForReviewsCompaniesOutsidePlanGal < ActiveRecord::Migration[6.0]
  def change
    add_column :business_unit_types, :without_number, :boolean, default: false, null: false
    add_column :business_unit_types, :reviews_for, :string, null: true
    add_column :business_unit_types, :detailed_review, :string, null: true
  end
end
