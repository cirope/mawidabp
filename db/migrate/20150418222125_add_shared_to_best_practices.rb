class AddSharedToBestPractices < ActiveRecord::Migration
  def change
    change_table :best_practices do |t|
      t.boolean :shared, default: false, null: false, index: true
      t.references :group, null: false, index: true
    end

    add_foreign_key :best_practices, :groups, options: FOREIGN_KEY_OPTIONS
  end
end
