class CreateReadings < ActiveRecord::Migration[5.1]
  def change
    create_table :readings do |t|
      t.references :user, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :readable, null: false, polymorphic: true, index: true
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
