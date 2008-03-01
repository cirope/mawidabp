class CreateHelpItems < ActiveRecord::Migration
  def self.up
    create_table :help_items do |t|
      t.string :name
      t.text :description
      t.integer :order_number
      t.references :help_content
      t.references :parent
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :help_items, :help_content_id
    add_index :help_items, :parent_id
  end

  def self.down
    remove_index :help_items, :column => :help_content_id
    remove_index :help_items, :column => :parent_id

    drop_table :help_items
  end
end