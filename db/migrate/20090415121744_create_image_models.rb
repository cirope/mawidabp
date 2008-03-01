class CreateImageModels < ActiveRecord::Migration
  def self.up
    create_table :image_models do |t|
      t.integer :parent_id
      t.string :thumbnail
      t.string :filename
      t.string :content_type
      t.integer :size
      t.integer :height
      t.integer :width
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :image_models, :parent_id
  end

  def self.down
    remove_index :image_models, :column => :parent_id

    drop_table :image_models
  end
end
