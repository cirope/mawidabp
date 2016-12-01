class AddIconToTags < ActiveRecord::Migration
  def change
    add_column :tags, :icon, :string, null: false, default: 'tag'
  end
end
