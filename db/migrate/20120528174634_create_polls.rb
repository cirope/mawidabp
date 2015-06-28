class CreatePolls < ActiveRecord::Migration
  def change
    create_table :polls do |t|
      t.text :comments
      t.boolean :answered, :default => false
      t.integer :lock_version, :default => 0
      t.references :user
      t.references :questionnaire
      t.references :pollable, :polymorphic => true
      t.timestamps null: false
    end

    add_index :polls, :questionnaire_id
  end
end
