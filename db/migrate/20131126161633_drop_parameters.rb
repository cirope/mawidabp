class DropParameters < ActiveRecord::Migration[4.2]
  def change
    drop_table :parameters
  end
end
