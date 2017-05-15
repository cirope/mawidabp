class CreateTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table :taggings do |t|
      t.references :tag, index: true, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :taggable, index: true, polymorphic: true, null: false

      t.timestamps null: false
    end
  end
end
