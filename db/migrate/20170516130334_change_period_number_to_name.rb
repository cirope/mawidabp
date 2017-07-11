class ChangePeriodNumberToName < ActiveRecord::Migration[5.0]
  class Period < ActiveRecord::Base
  end

  def change
    add_column :periods, :name, :string

    Period.reset_column_information

    Period.all.each do |period|
      period.update_column :name, period.number.to_s
    end

    remove_column :periods, :number
  end
end
