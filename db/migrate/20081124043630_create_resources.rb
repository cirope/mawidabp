class CreateResources < ActiveRecord::Migration[4.2]
  def self.up
    create_table :resources do |t|
      t.string :name
      t.text :description
      t.decimal :cost_per_unit, :precision => 15, :scale => 2
      t.references :resource_class
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :resources, :resource_class_id
  end

  def self.down
    remove_index :resources, :column => :resource_class_id

    drop_table :resources
  end
end
