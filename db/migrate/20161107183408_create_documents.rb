class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :name, null: false, index: true
      t.text :description
      t.boolean :shared, null: false, default: false, index: true
      t.integer :lock_version, default: 0
      t.references :file_model, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :organization, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :group, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
