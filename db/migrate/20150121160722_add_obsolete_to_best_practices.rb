class AddObsoleteToBestPractices < ActiveRecord::Migration[4.2]
  def change
    add_column :best_practices, :obsolete, :boolean, default: false
    add_column :process_controls, :obsolete, :boolean, default: false
    add_column :control_objectives, :obsolete, :boolean, default: false

    add_index :best_practices, :obsolete
    add_index :process_controls, :obsolete
    add_index :control_objectives, :obsolete
  end
end
