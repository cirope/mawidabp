class AddRequireCountsToBusinessUnitTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :business_unit_types, :require_counts, :boolean, default: false, null: false
  end
end
