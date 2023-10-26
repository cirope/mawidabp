class CreateRiskRegistries < ActiveRecord::Migration[6.1]
  def change
    create_table :risk_registries do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.references :group, null: false, index: true, foreign_key: true
      t.references :organization, null: false, index: true, foreign_key: true
      t.integer :lock_version, default: 0

      t.timestamps
    end
  end
end
