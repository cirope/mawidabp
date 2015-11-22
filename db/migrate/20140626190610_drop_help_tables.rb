class DropHelpTables < ActiveRecord::Migration
  def change
    drop_table :inline_helps
    drop_table :help_items
    drop_table :help_contents
  end
end
