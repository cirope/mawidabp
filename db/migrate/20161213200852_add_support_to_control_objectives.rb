class AddSupportToControlObjectives < ActiveRecord::Migration[4.2]
  def change
    add_column :control_objectives, :support, :string
  end
end
