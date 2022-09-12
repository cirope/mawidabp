class AddGroupedByBusinessUnitAnnualReportInBusinessUnitTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :business_unit_types, :grouped_by_business_unit_annual_report, :boolean, default: false
  end
end
