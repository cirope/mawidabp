class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :name, null: false
      t.string :value, null: false
      t.text :description
      t.references :organization, null: false, index: true
      t.integer :lock_version, default: 0

      t.timestamps null: false
    end

    add_index :settings, :name
    add_index :settings, [:name, :organization_id], unique: true
    add_foreign_key :settings, :organizations, FOREIGN_KEY_OPTIONS.dup
  end
end
