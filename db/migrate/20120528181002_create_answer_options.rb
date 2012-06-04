class CreateAnswerOptions < ActiveRecord::Migration
  def change
    create_table :answer_options do |t|
      t.text :option
      t.references :question
      t.integer :lock_version, :default => 0
      t.timestamps
    end
    
    add_index :answer_options, [:option, :question_id]
    
  end
end
