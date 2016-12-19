class AddSupportToControlObjectives < ActiveRecord::Migration
  def change
    add_column :control_objectives, :support, :string
  end
end
