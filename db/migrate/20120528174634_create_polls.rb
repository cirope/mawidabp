class CreatePolls < ActiveRecord::Migration
  def change
    create_table :polls do |t|
      t.text :comments
      t.references :questionnaire
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  
    add_index :polls, :questionnaire_id
    
  end
end
