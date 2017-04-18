class CreateWorkflows < ActiveRecord::Migration[4.2]
  def self.up
    create_table :workflows do |t|
      t.references :review
      t.references :period
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :workflows, :review_id
    add_index :workflows, :period_id
  end

  def self.down
    remove_index :workflows, :column => :review_id
    remove_index :workflows, :column => :period_id

    drop_table :workflows
  end
end
