class RemoveQaColumnsFromFindings < ActiveRecord::Migration
  def change
    remove_column :findings, :correction, :text
    remove_column :findings, :correction_date, :date
    remove_column :findings, :cause_analysis, :text
    remove_column :findings, :cause_analysis_date, :date
  end
end
