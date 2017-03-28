class CreateHelpContents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :help_contents do |t|
      t.string :language
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :help_contents, :language, :unique => true
  end

  def self.down
    remove_index :help_contents, :column => :language

    drop_table :help_contents
  end
end
