class CreateResourceClasses < ActiveRecord::Migration
  def self.up
    create_table :resource_classes do |t|
      t.string :name
      t.integer :unit
      t.integer :resource_class_type
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :resource_classes, :organization_id
  end

  def self.down
    remove_index :resource_classes, :column => :organization_id

    drop_table :resource_classes
  end
end