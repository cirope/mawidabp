class AddExecSummaryIntroToBusinessUnitTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :business_unit_types, :exec_summary_intro, :text
  end
end
