class CreateRelatedUserRelations < ActiveRecord::Migration
  def change
    create_table :related_user_relations do |t|
      t.references :user
      t.references :related_user

      t.timestamps null: false
    end

    add_index :related_user_relations, [:user_id, :related_user_id]
  end
end
