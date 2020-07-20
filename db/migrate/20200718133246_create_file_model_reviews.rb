class CreateFileModelReviews < ActiveRecord::Migration[6.0]
  def change
    create_table :file_model_reviews do |t|
      t.references :file_model, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :review, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
