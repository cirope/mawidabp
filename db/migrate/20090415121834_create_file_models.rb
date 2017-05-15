class CreateFileModels < ActiveRecord::Migration[4.2]
  def self.up
    create_table :file_models do |t|
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :file_models
  end
end
