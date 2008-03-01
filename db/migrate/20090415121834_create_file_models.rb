class CreateFileModels < ActiveRecord::Migration
  def self.up
    create_table :file_models do |t|
      t.string :filename
      t.string :content_type
      t.integer :size
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :file_models
  end
end