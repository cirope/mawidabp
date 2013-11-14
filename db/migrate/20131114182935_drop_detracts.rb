class DropDetracts < ActiveRecord::Migration
  def change
    drop_table :detracts
  end
end
