class AddCorrectionAndCorrectionDateToFindings < ActiveRecord::Migration
  def change
    add_column :findings, :correction, :string
    add_column :findings, :correction_date, :date
  end
end
