class AddFieldsBicToFindings < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :year, :string
    add_column :findings, :nsisio, :string
    add_column :findings, :nobs, :string
  end
end
