class CreateTimeConsumptions < ActiveRecord::Migration[6.0]
  def change
    create_table :time_consumptions do |t|
      t.date :date, null: false
      t.decimal :amount, null: false, precision: 3, scale: 1
      t.references :activity, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.references :user, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
