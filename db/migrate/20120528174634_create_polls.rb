class CreatePolls < ActiveRecord::Migration
  def change
    create_table :polls do |t|
      t.text :comments
      t.boolean :answered
      t.integer :lock_version, :default => 0
      t.references :user
      t.references :questionnaire
      t.references :pollable, :polymorphic => true
      t.timestamps
    end
  
    add_index :polls, :questionnaire_id
    
  end
end
