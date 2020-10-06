class CreateBestPracticeProjects < ActiveRecord::Migration[6.0]
  def change
    create_table :best_practice_projects do |t|
      t.references :best_practice, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :plan_item, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
