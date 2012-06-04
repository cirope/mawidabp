class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :sort_order
      t.integer :answer_type
      t.text :question
      t.references :questionnaire
      t.integer :lock_version, :default => 0
      t.timestamps
    end
    
    add_index :questions, [:question, :questionnaire_id]
    
  end
end
