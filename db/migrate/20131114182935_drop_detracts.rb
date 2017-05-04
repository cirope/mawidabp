class DropDetracts < ActiveRecord::Migration[4.2]
  def change
    drop_table :detracts
  end
end
