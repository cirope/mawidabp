class AddOpenInAnnualReport < ActiveRecord::Migration[6.1]
  def change
    add_column :business_unit_types, :open_in_annual_report, :boolean, default: false
  end
end
