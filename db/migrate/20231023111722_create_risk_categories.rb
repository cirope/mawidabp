class CreateRiskCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :risk_categories do |t|
      t.string :name, null: false
      t.references :risk_registry, null: false, index: true, foreign_key: true

      t.timestamps
    end
  end
end
