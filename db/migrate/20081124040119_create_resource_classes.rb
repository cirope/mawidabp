class CreateResourceClasses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :resource_classes do |t|
      t.string :name
      t.integer :unit
      t.integer :resource_class_type
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :resource_classes, :organization_id
    add_index :resource_classes, :name
  end

  def self.down
    remove_index :resource_classes, :column => :organization_id
    remove_index :resource_classes, :column => :name

    drop_table :resource_classes
  end
end
