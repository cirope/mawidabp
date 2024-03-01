class AddDescriptionToTaggings < ActiveRecord::Migration[6.1]
  def change
    add_column :taggings, :description, :text
  end
end
