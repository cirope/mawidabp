class CreateQuestionnaires < ActiveRecord::Migration
  def change
    create_table :questionnaires do |t|
      t.string :name
      t.integer :lock_version, :default => 0
      t.timestamps
    end
    
    add_index :questionnaires, :name
    
  end
end
