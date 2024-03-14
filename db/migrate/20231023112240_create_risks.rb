class CreateRisks < ActiveRecord::Migration[6.1]
  def change
    create_table :risks do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.integer :likelihood, null: false
      t.integer :impact, null: false
      t.text :cause
      t.text :effect
      t.references :user, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :risk_category, null: false, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps
    end
  end
end
