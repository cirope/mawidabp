class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.text :comments
      t.string :type
      t.references :question
      t.references :poll
      t.integer :lock_version, :default => 0
      # AnswerWritten
      t.text :answer
      # AnswerMultiChoice
      t.references :answer_option 
      t.timestamps null: false
    end

    add_index :answers, :question_id
    add_index :answers, :poll_id
    add_index :answers, [:type, :id]
  end
end
