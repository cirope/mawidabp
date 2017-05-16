class ChangePeriodNumberToName < ActiveRecord::Migration[5.0]
  def change
    change_column :periods, :number, :string
    rename_column :periods, :number, :name
  end
end
