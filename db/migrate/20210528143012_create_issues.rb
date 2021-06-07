class CreateIssues < ActiveRecord::Migration[6.0]
  def change
    create_table :issues do |t|
      t.string :customer
      t.string :entry
      t.string :operation
      t.decimal :amount, precision: 15, scale: 2
      t.text :comments
      t.date :close_date
      t.references :finding, null: false, index: true,
        foreign_key: FOREIGN_KEY_OPTIONS.dup

      t.timestamps null: false
    end
  end
end
