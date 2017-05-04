class CreateFindingAnswers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :finding_answers do |t|
      t.text :answer
      t.text :auditor_comments
      t.date :commitment_date
      t.references :finding
      t.references :user
      t.references :file_model

      t.timestamps null: false
    end

    add_index :finding_answers, :finding_id
    add_index :finding_answers, :user_id
    add_index :finding_answers, :file_model_id
  end

  def self.down
    remove_index :finding_answers, :column => :finding_id
    remove_index :finding_answers, :column => :user_id
    remove_index :finding_answers, :column => :file_model_id

    drop_table :finding_answers
  end
end
