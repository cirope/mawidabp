class AddDetailedReviewLegendToBusinessUnitType < ActiveRecord::Migration[6.1]
  def change
    add_column :business_unit_types, :detailed_review_legend, :text
  end
end
