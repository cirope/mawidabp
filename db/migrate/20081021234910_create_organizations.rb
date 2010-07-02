class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      t.string :name
      t.string :prefix
      t.text :description
      t.references :group
      t.references :image_model
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :organizations, :prefix, :unique => true
    add_index :organizations, :group_id
    add_index :organizations, :image_model_id
  end

  def self.down
    remove_index :organizations, :column => :prefix
    remove_index :organizations, :column => :group_id
    remove_index :organizations, :column => :image_model_id

    drop_table :organizations
  end
end