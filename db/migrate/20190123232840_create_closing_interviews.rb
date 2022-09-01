class CreateClosingInterviews < ActiveRecord::Migration[5.2]
  def change
    create_table :closing_interviews do |t|
      t.date :interview_date, null: false
      t.text :findings_summary
      t.text :recommendations_summary
      t.text :suggestions
      t.text :comments
      t.text :audit_comments
      t.text :responsible_comments
      t.integer :lock_version, null: false, default: 0
      t.references :review, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end

    add_index :closing_interviews, :interview_date
  end
end
