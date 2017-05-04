class DropHelpTables < ActiveRecord::Migration[4.2]
  def change
    drop_table :inline_helps
    drop_table :help_items
    drop_table :help_contents
  end
end
