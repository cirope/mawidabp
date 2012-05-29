class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :sort_order
      t.integer :answer_type
      t.text :question
      t.timestamps
    end
  end
end
