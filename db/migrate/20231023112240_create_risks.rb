class CreateRisks < ActiveRecord::Migration[6.1]
  def change
    create_table :risks do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.text :cause
      t.text :effect
      t.string :likelihood
      t.string :consequence
      t.references :user, null: false, index: true, foreign_key: true
      t.references :risk_category, null: false, index: true, foreign_key: true

      t.timestamps
    end
  end
end
