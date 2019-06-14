class AddParentIdToTags < ActiveRecord::Migration[5.2]
  def change
    add_reference :tags, :parent, index: true
  end
end
