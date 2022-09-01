class CreateClosingInterviewUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :closing_interview_users do |t|
      t.string :kind, null: false
      t.references :closing_interview, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :user, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
