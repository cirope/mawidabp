class AddCauseAnalysisAndCauseAnalysisDateToFindings < ActiveRecord::Migration
  def change
    add_column :findings, :cause_analysis, :string
    add_column :findings, :cause_analysis_date, :date
  end
end
