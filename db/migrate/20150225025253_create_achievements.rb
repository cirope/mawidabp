class CreateAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
      t.references :benefit, index: true, null: false
      t.decimal :amount, precision: 15, scale: 2
      t.text :comment
      t.references :finding, index: true, null: false

      t.timestamps
    end

    add_foreign_key :achievements, :benefits, options: FOREIGN_KEY_OPTIONS
    add_foreign_key :achievements, :findings, options: FOREIGN_KEY_OPTIONS
  end
end
