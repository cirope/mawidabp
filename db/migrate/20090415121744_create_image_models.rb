class CreateImageModels < ActiveRecord::Migration
  def self.up
    create_table :image_models do |t|
      t.string :image_file_name
      t.string :image_content_type
      t.integer :image_file_size
      t.datetime :image_updated_at
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :image_models
  end
end
