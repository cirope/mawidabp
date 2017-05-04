class AddTitleToFindings < ActiveRecord::Migration[4.2]
  def change
    add_column :findings, :title, :string
  end
end
