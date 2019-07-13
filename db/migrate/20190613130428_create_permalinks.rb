class CreatePermalinks < ActiveRecord::Migration[5.2]
  def change
    create_table :permalinks do |t|
      t.string :token, null: false, index: { unique: true }
      t.string :action, null: false
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.datetime :created_at, null: false
    end
  end
end
