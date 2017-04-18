class AddCorrectionAndCorrectionDateToFindings < ActiveRecord::Migration[4.2]
  def change
    add_column :findings, :correction, :string
    add_column :findings, :correction_date, :date
  end
end
