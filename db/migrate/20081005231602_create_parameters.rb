class CreateParameters < ActiveRecord::Migration
  def self.up
    create_table :parameters do |t|
      t.string :name, :limit => 100
      t.text :value
      t.text :description
      t.references :organization
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :parameters, :organization_id
    add_index :parameters, [:name, :organization_id], :unique => true
  end

  def self.down
    remove_index :parameters, :column => :organization_id
    remove_index :parameters, :column => [:name, :organization_id]

    drop_table :parameters
  end
end