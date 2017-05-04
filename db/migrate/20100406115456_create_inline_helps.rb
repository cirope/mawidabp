class CreateInlineHelps < ActiveRecord::Migration[4.2]
  def self.up
    create_table :inline_helps do |t|
      t.string :language
      t.string :name
      t.text :content
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :inline_helps, :name
    add_index :inline_helps, :language
  end

  def self.down
    remove_index :inline_helps, :column => :name
    remove_index :inline_helps, :column => :language

    drop_table :inline_helps
  end
end
