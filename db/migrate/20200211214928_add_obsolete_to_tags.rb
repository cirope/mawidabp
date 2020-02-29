class AddObsoleteToTags < ActiveRecord::Migration[6.0]
  def change
    change_table :tags do |t|
      t.boolean :obsolete, null: false, default: false
    end

    add_index :tags, :obsolete
  end
end
