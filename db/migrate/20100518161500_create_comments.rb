class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text :comment
      t.references :commentable, :polymorphic => true
      t.references :user

      t.timestamps null: false
    end

    add_index :comments, :commentable_type
    add_index :comments, :commentable_id
    add_index :comments, :user_id
  end

  def self.down
    remove_index :comments, :column => :commentable_type
    remove_index :comments, :column => :commentable_id
    remove_index :comments, :column => :user_id

    drop_table :comments
  end
end
