class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.text :comments
      t.references :question
      t.references :poll
      t.integer :lock_version, :default => 0
      # AnswerWritten
      t.text :answer
      # AnswerMultiChoice
      t.references :answer_option 
      t.timestamps
    end
    
    add_index :answers, [:answer, :question_id, :poll_id]
    
  end
end
