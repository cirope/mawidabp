class AddRequireTagToBusinessUnitTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :business_unit_types, :require_tag, :boolean, default: false, null: false
  end
end
