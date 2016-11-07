class AddSharedAndGroupIdToTags < ActiveRecord::Migration
  def change
    add_column :tags, :shared, :boolean, null: false, default: false
    add_reference :tags, :group, index: true, foreign_key: FOREIGN_KEY_OPTIONS.dup

    add_index :tags, :shared

    put_group_id_on_tags

    change_column_null :tags, :group_id, false
  end

  private

    def put_group_id_on_tags
      Tag.reset_column_information

      Tag.unscoped.all.includes(:organization).find_each do |tag|
        tag.update! group_id: tag.organization.group_id
      end
    end
end
