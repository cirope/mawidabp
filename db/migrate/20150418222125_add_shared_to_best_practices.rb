class AddSharedToBestPractices < ActiveRecord::Migration
  def change
    change_table :best_practices do |t|
      t.boolean :shared, default: false, index: true
      t.references :group, index: true
    end

    add_foreign_key :best_practices, :groups, FOREIGN_KEY_OPTIONS.dup
  end
end
