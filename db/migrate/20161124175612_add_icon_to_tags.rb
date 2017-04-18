class AddIconToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :icon, :string, null: false, default: 'tag'
  end
end
