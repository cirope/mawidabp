class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.string :identification
      t.text :description
      t.text :survey
      t.integer :score
      t.integer :top_scale
      t.integer :achieved_scale
      t.references :period
      t.references :plan_item
      t.references :file_model
      t.integer :lock_version, :default => 0

      t.timestamps null: false
    end

    add_index :reviews, :period_id
    add_index :reviews, :plan_item_id
    add_index :reviews, :file_model_id
    add_index :reviews, :identification
  end

  def self.down
    remove_index :reviews, :column => :period_id
    remove_index :reviews, :column => :plan_item_id
    remove_index :reviews, :column => :file_model_id
    remove_index :reviews, :column => :identification

    drop_table :reviews
  end
end
