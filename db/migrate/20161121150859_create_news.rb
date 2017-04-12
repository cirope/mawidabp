class CreateNews < ActiveRecord::Migration[4.2]
  def change
    create_table :news do |t|
      t.string :title, null: false
      t.text :description
      t.text :body, null: false
      t.boolean :shared, null: false, default: false
      t.datetime :published_at, null: false
      t.integer :lock_version, default: 0
      t.references :organization, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :group, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end

    change_column_default :news, :shared, false # Oracle Fix

    add_index :news, :shared
    add_index :news, :published_at
  end
end
