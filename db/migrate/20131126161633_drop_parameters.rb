class DropParameters < ActiveRecord::Migration
  def change
    drop_table :parameters
  end
end
