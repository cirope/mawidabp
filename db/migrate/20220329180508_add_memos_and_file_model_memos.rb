class AddMemosAndFileModelMemos < ActiveRecord::Migration[6.0]
  def change
    create_table :memos do |t|
      t.string :name
      t.text :description
      t.date :close_date
      t.string :required_by
      t.references :period, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :plan_item, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :organization, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.timestamps
    end

    create_table :file_model_memos do |t|
      t.references :file_model, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :memo, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
