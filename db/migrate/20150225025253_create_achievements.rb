class CreateAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
      t.references :benefit, index: true, null: false
      t.decimal :amount, precision: 15, scale: 2
      t.text :comment
      t.references :finding, index: true, null: false

      t.timestamps null: false
    end

    add_foreign_key :achievements, :benefits, FOREIGN_KEY_OPTIONS.dup
    add_foreign_key :achievements, :findings, FOREIGN_KEY_OPTIONS.dup
  end
end
