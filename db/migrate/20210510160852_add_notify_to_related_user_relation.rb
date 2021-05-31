class AddNotifyToRelatedUserRelation < ActiveRecord::Migration[6.0]
  def change
    change_table :related_user_relations do |t|
      t.boolean :notify, default: false, null: false
    end
  end
end
