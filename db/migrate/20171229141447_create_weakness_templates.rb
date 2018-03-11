class CreateWeaknessTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :weakness_templates do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.integer :risk
      t.text :impact, null: false, array: true, default: [].to_json
      t.text :operational_risk, null: false, array: true, default: [].to_json
      t.text :internal_control_components, null: false, array: true, default: [].to_json
      t.integer :lock_version, null: false, default: 0
      t.references :organization, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
