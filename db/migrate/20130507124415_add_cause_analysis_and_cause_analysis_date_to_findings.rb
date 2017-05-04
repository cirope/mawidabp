class AddCauseAnalysisAndCauseAnalysisDateToFindings < ActiveRecord::Migration[4.2]
  def change
    add_column :findings, :cause_analysis, :string
    add_column :findings, :cause_analysis_date, :date
  end
end
