class CreateAnswerOptions < ActiveRecord::Migration
  def change
    create_table :answer_options do |t|
      t.text :option
      t.references :question
      t.timestamps
    end
  end
end
