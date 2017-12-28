class DropProcessControlComments < ActiveRecord::Migration[5.1]
  def change
    drop_table :process_control_comments
  end
end
