class CreateBestPracticeComments < ActiveRecord::Migration[5.1]
  def change
    create_table :best_practice_comments do |t|
      t.text :auditor_comment
      t.references :review, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :best_practice, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
