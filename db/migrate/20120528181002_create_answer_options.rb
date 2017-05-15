class CreateAnswerOptions < ActiveRecord::Migration[4.2]
  def change
    create_table :answer_options do |t|
      t.text :option
      t.references :question
      t.integer :lock_version, :default => 0
      t.timestamps null: false
    end

    add_index :answer_options, :question_id
  end
end
