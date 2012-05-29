class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.text :comments
      t.references :question
      t.references :poll
      # AnswerWritten
      t.text :answer
      # AnswerMultiChoice
      t.references :answer_option 
      t.timestamps
    end
  end
end
