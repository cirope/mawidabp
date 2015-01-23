class AddTitleToFindings < ActiveRecord::Migration
  def change
    add_column :findings, :title, :string
  end
end
