class AddCodeToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :code, :string
  end
end
