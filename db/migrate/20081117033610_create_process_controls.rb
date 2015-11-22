class CreateProcessControls < ActiveRecord::Migration
  def self.up
    create_table :process_controls do |t|
      t.string :name
      t.integer :order
      t.references :best_practice

      t.timestamps null: false
    end

    add_index :process_controls, :best_practice_id
  end

  def self.down
    remove_index :process_controls, :column => :best_practice_id

    drop_table :process_controls
  end
end
