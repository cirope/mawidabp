class CreateOpeningInterviews < ActiveRecord::Migration[5.2]
  def change
    create_table :opening_interviews do |t|
      t.date :interview_date, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :objective, null: false
      t.text :program
      t.text :scope
      t.text :suggestions
      t.text :comments
      t.integer :lock_version, null: false, default: 0
      t.references :review, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end

    add_index :opening_interviews, :interview_date
  end
end
